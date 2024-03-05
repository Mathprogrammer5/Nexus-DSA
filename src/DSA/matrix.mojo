'''Contains the `Matrix` struct.'''
from .mdtensorwrapper import MDTensorWrapper
from .vector import Vector
from random import seed, rand
from tensor import TensorShape

struct Matrix[type: DType](MDTensorWrapper):
  '''Defines a wrapper to handle mathematical matrices.'''

  var data: Tensor[type]
  var x: Int
  var y: Int

  fn __init__(inout self) raises:
    self.data = Tensor[type]()
    self.x = 0
    self.y = 0

  fn __init__(inout self, owned x: Int, owned y: Int):
    self.x = x
    self.y = y
    self.data = Tensor[type](x, y)

  fn __init__(inout self, owned data: Tensor[type]) raises:
    if data.rank() != 2:
      raise Error("Unable to convert given data to a matrix due to rank mismatch")
    self.data = data
    self.x = data.dim(0)
    self.y = data.dim(1)

  fn __copyinit__(inout self, borrowed other: Self):
    self.data = other.data
    self.x = other.x
    self.y = other.y

  fn __moveinit__(inout self, owned other: Self):
    self.data = other.data
    self.x = other.x
    self.y = other.y

  @always_inline
  fn __mul__(self, owned vec: Vector[type]) raises-> Vector[type]:
    '''Defines function for matrix-vector multiplication.'''
    if vec.data.dim(0) != self.data.dim(1):
      raise Error("Cannot multiply due to dimension mismatch")

    var val = Vector[type](self.data.dim(0))

    for i in range(self.data.dim(0)):
      # multiplies input vector with rows of matrix
      val.data[i] = vec * 
        Vector(
          # returns the i-th row of the matrix as Tensor value
          self.data.clip(
            self.data.dim(1)*i, 
            self.data.dim(1)*(i+1)-1
          )
        )
    
    return val

  @always_inline
  fn __rmul__(self, vec: Vector[type]) raises-> Vector[type]:
    '''Defines function for matrix-vector multiplication.'''
    return self.__mul__(vec)

  fn flatten(inout self) raises -> Vector[type]:
    '''Returns all values of the underlying `Tensor` value in a `Vector`.'''
    return Vector[type](
      self.data.reshape(
        TensorShape(
          self.x * self.y
          )
        )
      )

  fn random_matrix(inout self, x: Int, y: Int) raises:
    '''Defines function for generating random matrices with `Float64` values.'''
    seed()
    self.data = rand[type](x, y)

  @staticmethod
  fn matrix_applicable[type: DType](
    func: fn(x: SIMD[type, 1], a: SIMD[type, 1]) -> SIMD[type, 1]
    ) -> 
    fn(x: Matrix[type], a: SIMD[type, 1]) raises escaping -> Matrix[type]:
      
    '''Takes a function with a parameter and returns it equivalent for the `Matrix` type.'''
    @always_inline
    fn matfunc(matrix: Matrix[type], a: SIMD[type, 1]) raises escaping -> Matrix[type]:
      var val = Matrix[type](matrix.x, matrix.y)
      for i in range(matrix.x):
        for j in range(matrix.y):
          
          val.data.simd_store[1](
            VariadicList(i, j), 
            func(
              matrix.data.simd_load[1](i, j), a
              )
            )

      return val
    
    return matfunc

alias MLMatrix = Matrix[f32]
'''`Matrix` containing `DType.float32` values, useful for ML applications.'''

alias GPUMatrix = Matrix[tf32]
'''
`Matrix` containing values of Mojo's special `DType.tensor_float32` type. 

Note that this requires a NVIDIA GPU.
'''