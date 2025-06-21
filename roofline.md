모든 GPU 커널은 두 가지 기본적인 제약 조건 하에서 작동합니다:

*   **연산 성능 한계(Compute ceiling)** – 코어가 부동 소수점 연산을 얼마나 빨리 실행할 수 있는지 (최대 FLOPs/s)
*   **메모리 성능 한계(Memory ceiling)** – 메모리 시스템이 코어에 데이터를 얼마나 빨리 공급할 수 있는지 (최대 bytes/s)

어떤 한계가 커널을 제약하는지 이해하는 것은 최적화 전략에 매우 중요합니다. Roofline 모델은 두 가지 주요 지표를 그려 이 관계를 시각화합니다:

*   **X축: 연산 강도(Arithmetic Intensity)** – 데이터 1바이트당 얼마나 많은 연산을 수행하는가
    `I = 총 FLOPs / 메모리로부터의 총 바이트 [FLOP/B]`
*   **Y축: 지속 성능(Sustained Performance)** – 커널이 실제로 얼마나 빨리 실행되는가
    `Psustained = 총 FLOPs / 경과 시간 [GFLOP/s]`

두 개의 "지붕(roof)"이 달성 가능한 모든 성능을 제한합니다:

| 지붕 (Roof) | 방정식 (Equation) | 의미 (Meaning) |
| :--- | :--- | :--- |
| 메모리 지붕 (Memory roof) | `P = Bpeak ⋅ I` | 기울어진 선; 메모리 대역폭에 의해 성능이 제한됨 |
| 연산 지붕 (Compute roof) | `P = Ppeak` | 수평선; 연산 처리량에 의해 성능이 제한됨 |

임계 강도(critical intensity) `I∗ = Ppeak / Bpeak`는 커널이 메모리 바운드(`I < I∗`)에서 연산 바운드(`I > I∗`)로 전환되는 지점을 나타냅니다.

## Roofline 모델을 활용한 최적화 전략

Roofline 모델은 현재 성능을 진단할 뿐만 아니라 최적화 경로를 제시합니다. 다음은 주요 최적화 기법들입니다.

### 주요 최적화 기법

| 기법 (Technique) | Roofline 효과 (Effect) | 구현 접근 방식 (Approach) |
| :--- | :--- | :--- |
| **Shared memory tiling** | 데이터 재사용을 통한 연산 강도(Arithmetic Intensity) 향상 (↑) | 협력적 로딩, 블록 단위 계산 |
| **Register blocking** | 레지스터 누적을 통한 메모리 트래픽 감소 | 레지스터 변수를 사용한 루프 언롤링 |
| **Kernel fusion** | 연산 결합을 통한 바이트당 FLOPs 증가 | 여러 계산 단계를 처리하는 단일 커널 |
| **Memory coalescing** | 구조화된 접근 패턴을 통한 유효 대역폭 극대화 | 구조화된 접근 패턴, 적절한 스레드 구성 |
| **Mixed precision** | 작은 데이터 타입을 사용한 메모리 부담 감소 | FP16/BF16 입력과 FP32 누적 |

각 기법은 커널을 Roofline 모델 상에서 이동시킵니다. 메모리 한계선(memory roof) 위로 이동시키거나(더 나은 대역폭 활용), 연산 한계선(compute roof) 오른쪽으로 이동시킵니다(더 높은 연산 강도).

### 단순한 Roofline 모델을 넘어서

- **다중 레벨 메모리 (Multi-level memory):** L2 캐시, 공유 메모리, 레지스터 대역폭에 대한 별도의 한계선을 포함하여 어떤 메모리 계층이 성능을 제한하는지 식별합니다.
- **통신 Roofline (Communication rooflines):** 다중 GPU 애플리케이션의 경우, 메모리 대역폭을 상호 연결 대역폭(NVLink, InfiniBand)으로 대체하여 확장 효율성을 분석합니다.
- **특수 유닛 (Specialized units):** 최신 GPU의 텐서 코어와 같이 자체 성능 특성을 가진 유닛은 특화된 Roofline 분석이 필요합니다.

### 실제 Roofline 사용법

1.  **커널 프로파일링:** Nsight Compute와 같은 도구를 사용하여 실제 FLOPs와 메모리 트래픽을 측정합니다.
2.  **데이터 포인트 플로팅:** 연산 강도와 지속 성능을 계산하여 그래프에 표시합니다.
3.  **병목 현상 식별:**
    -   **메모리 바운드(Memory-bound):** 커널이 메모리 한계선 위에 위치합니다.
    -   **연산 바운드(Compute-bound):** 커널이 연산 한계선에 접근합니다.
4.  **최적화 선택:**
    -   메모리 바운드 커널: 대역폭 개선에 집중합니다.
    -   연산 바운드 커널: 알고리즘 변경에 집중합니다.
5.  **측정 및 반복:** 최적화가 커널을 예상 방향으로 이동시키는지 확인합니다.
