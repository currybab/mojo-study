# Bridging to Python with MAX Graph

## 목표

- 사용자 정의 연산 등록: `@compiler.register` 데코레이터를 통해 Mojo 함수를 Python에 노출하는 방법 이해
- 사용자 정의 연산 패키징: MAX Graph와 함께 사용하기 위해 Mojo 코드를 패키징하는 방법 학습
- Python 통합: MAX Graph를 통해 Python에서 사용자 정의 연산 호출
- 언어 간 데이터 흐름: Python과 GPU 간의 데이터 유형 및 메모리 관리

## 사용자 정의 연산이 수행하는 것

- NumPy 배열을 Python에서 입력으로 수락
- 이 데이터를 GPU로 전송
- 최적화된 컨볼루션 커널을 실행
- 결과를 Python으로 반환

## 사용자 정의 연산 등록

사용자 정의 연산을 만드는 핵심은 `@compiler.register` 데코레이터와 관련 구조입니다:

```
@compiler.register("conv1d")
struct Conv1DCustomOp:
    @staticmethod
    fn execute[...](
        output: OutputTensor[rank=1],
        input: InputTensor[dtype = output.dtype, rank = output.rank],
        kernel: InputTensor[type = output.dtype, rank = output.rank],
        ctx: DeviceContextPtr,
    ) raises:
```

### 등록의 주요 구성 요소:

- 데코레이터에 전달된 이름("conv1d")은 Python 코드가 이 연산을 호출하는 데 사용됩니다.
- 구조체는 올바른 시그니처를 가진 `execute` 메서드를 가져야 합니다.
- `OutputTensor` 및 `InputTensor` 유형은 Python 데이터의 인터페이스를 정의합니다.
- `DeviceContextPtr`는 실행 환경에 대한 접근을 제공합니다.

## 사용자 정의 연산 패키징

사용자 정의 연산을 Python에서 사용하기 전에 패키징해야 합니다:

```bash
mojo package op -o op.mojopkg
```

이 명령어는:

- Mojo 코드를 배포 가능한 패키지로 컴파일합니다.
- MAX Graph가 연산을 이해하는 데 필요한 메타데이터를 생성합니다.
- Python에서 로드할 수 있는 바이너리 아티팩트(op.mojopkg)를 생성합니다.
- 패키지는 MAX Graph가 찾을 수 있는 위치, 일반적으로 Python 코드가 접근할 수 있는 디렉토리에 위치해야 합니다.

## Python 통합

Python 측에서는 다음과 같이 사용자 정의 연산을 사용합니다:

```python
# Mojo 연산이 포함된 디렉토리 경로
mojo_kernels = Path(__file__).parent / "op"

# 사용자 정의 conv1d 연산으로 그래프 구성
with Graph(
    "conv_1d_graph",
    input_types=[...],
    custom_extensions=[mojo_kernels],  # 사용자 정의 연산 패키지 로드
) as graph:
    # 그래프에 대한 입력 정의
    input_value, kernel_value = graph.inputs

    # 이름으로 사용자 정의 연산 사용
    output = ops.custom(
        name="conv1d",  # @compiler.register의 이름과 일치해야 함
        values=[input_value, kernel_value],
        out_types=[...],
        parameters={
            "input_size": input_tensor.shape[0],
            "conv_size": kernel_tensor.shape[0],
            "dtype": dtype,
        },
    )[0].tensor
```

주요 요소는 다음과 같습니다:

- `custom_extensions`로 사용자 정의 연산 경로 지정
- 등록된 연산 이름으로 `ops.custom` 호출
- 연산의 시그니처와 일치하는 입력 값 및 매개변수 전달
