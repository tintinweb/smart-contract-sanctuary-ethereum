# @version 0.3.7
# @dev Implementation of fivefiveswap router.
# @author Vykintas Maknickas (@vykintasm)

interface FiveFiveSwapFactory:
    def getPair(_tokenA: address, _tokenAId: uint256, _tokenB: address) -> address: view
    def createPair(_tokenA: address, _tokenAId: uint256, _tokenB: address) -> address: nonpayable

interface FiveFiveSwapPair:
    def getReserves() -> (uint112, uint112, uint32): view
    def transferFrom(_from : address, _to : address, amount : uint256) -> bool: nonpayable
    def permit(owner: address, spender: address, amount: uint256, deadline: uint256, v: uint8, r: bytes32, s: bytes32) -> bool: nonpayable
    def mint(to: address) -> uint256: nonpayable
    def burn(to: address) -> (uint256, uint256): nonpayable
    def swap(amount0Out: uint256, amount1Out: uint256, to: address, data: Bytes[256]): nonpayable

interface ERC1155:
    def balanceOf(account: address, id: uint256) -> uint256: nonpayable
    def safeTransferFrom(_from: address, to: address, id: uint256, amount: uint256, data: bytes32): nonpayable

interface IWETH:
    def deposit(): payable
    def transfer(to: address, amount: uint256) -> bool: nonpayable
    def withdraw(amount: uint256): nonpayable

factory: public(address)
weth: public(address)

MAX_INT: constant(uint256) = 115792089237316195423570985008687907853269984665640564039457584007913129639935
MAX_PATHS: constant(uint8) = 10
ZERO_BYTES: constant(bytes32) = 0x0000000000000000000000000000000000000000000000000000000000000000

@external
@payable
def __default__():
    assert msg.sender == self.weth # only accept ETH via fallback from the WETH contract

@external
def __init__(_factory: address, _weth: address):
    """
    @dev Contract constructor.
    @param _factory Sets address of the factory contract
    @param _weth Sets address for wETH contract
    """
    assert _factory != empty(address), "FiveFiveRouter: ZERO_ADDRESS"
    assert _weth != empty(address), "FiveFiveRouter: ZERO_ADDRESS"
    
    self.factory = _factory
    self.weth = _weth

@internal
@view
def _quote(_amountA: uint256, _reserveA: uint112, _reserveB: uint112) -> uint256:
    assert _amountA > 0, "FiveFiveRouter: INSUFFICIENT_AMOUNT"
    assert _reserveA > 0 and _reserveB > 0, "FiveFiveRouter: INSUFFICIENT_LIQUIDITY"

    return _amountA * convert(_reserveB, uint256) / convert(_reserveA, uint256)

@internal
@view
def _getAmountOut(_amountIn: uint256, _reserveIn: uint112, _reserveOut: uint112) -> uint256:
    assert _amountIn > 0, "FiveFiveRouter: INSUFFICIENT_INPUT_AMOUNT"
    assert _reserveIn > 0 and _reserveOut > 0, "FiveFiveRouter: INSUFFICIENT_LIQUIDITY"

    amountInWithFee: uint256 = _amountIn * 997
    numerator: uint256 = convert(ceil(convert(amountInWithFee * convert(_reserveOut, uint256), decimal)/1000.)*1000, uint256)
    denominator: uint256 = (convert(_reserveIn, uint256) * 1000) + amountInWithFee
    amountOut: uint256 = numerator / denominator

    return amountOut

@internal
@view
def _getAmountIn(_amountOut: uint256, _reserveIn: uint112, _reserveOut: uint112) -> uint256:
    assert _amountOut > 0, "FiveFiveRouter: INSUFFICIENT_INPUT_AMOUNT"
    assert _reserveIn > 0 and _reserveOut > 0, "FiveFiveRouter: INSUFFICIENT_LIQUIDITY"

    numerator: uint256 = convert(_reserveIn, uint256) * _amountOut * 1000
    denominator: uint256 = (convert(_reserveOut, uint256) - _amountOut) * 997
    amountIn: uint256 = numerator / denominator + 1

    return amountIn

@internal
@view
def _getAmountsOut(amountIn: uint256, path: DynArray[address, MAX_PATHS], tokenIds: DynArray[uint256, MAX_PATHS]) -> DynArray[uint256, MAX_PATHS]:
    assert len(path) >= 2, "FiveFiveRouter: INVALID_PATH"
    assert len(tokenIds) == len(path), "FiveFiveRouter: INVALID_PATH"

    amounts: DynArray[uint256, MAX_PATHS] = []
    amounts.append(amountIn)

    for i in range(MAX_PATHS-1):
        if i+1 == len(path):
            break

        reserveA: uint112 = 0
        reserveB: uint112 = 0
        blockTimestampLast: uint32 = 0

        if tokenIds[i] == 0:
            pairAddress: address = FiveFiveSwapFactory(self.factory).getPair(path[i+1], tokenIds[i+1], path[i])
            reserveB, reserveA, blockTimestampLast = FiveFiveSwapPair(pairAddress).getReserves()
        else:
            pairAddress: address = FiveFiveSwapFactory(self.factory).getPair(path[i], tokenIds[i], path[i+1])
            reserveA, reserveB, blockTimestampLast = FiveFiveSwapPair(pairAddress).getReserves()

        amounts.append(self._getAmountOut(amounts[i], reserveA, reserveB)) 

    return amounts

@internal
@view
def _getAmountsIn(amountOut: uint256, path: DynArray[address, MAX_PATHS], tokenIds: DynArray[uint256, MAX_PATHS]) -> DynArray[uint256, MAX_PATHS]:
    assert len(path) >= 2, "FiveFiveRouter: INVALID_PATH"

    amounts: DynArray[uint256, MAX_PATHS] = []
    amounts.append(amountOut)

    numAmounts: uint256 = 0

    pathLength: uint256 = len(path)

    for i in range(MAX_PATHS+0):
        x: uint256 = convert(MAX_PATHS, uint256) - i
        
        if x >= pathLength:
            continue

        reserveA: uint112 = 0
        reserveB: uint112 = 0
        blockTimestampLast: uint32 = 0
        
        if tokenIds[x] == 0:
            pairAddress: address = FiveFiveSwapFactory(self.factory).getPair(path[x-1], tokenIds[x-1], path[x])
            reserveA, reserveB, blockTimestampLast = FiveFiveSwapPair(pairAddress).getReserves()
        else:
            pairAddress: address = FiveFiveSwapFactory(self.factory).getPair(path[x], tokenIds[x], path[x-1])
            reserveB, reserveA, blockTimestampLast = FiveFiveSwapPair(pairAddress).getReserves()

        amounts.append(self._getAmountIn(amounts[numAmounts], reserveA, reserveB))
        numAmounts = numAmounts + 1

    return amounts

@internal
@nonpayable
def _swap(_amounts: DynArray[uint256, MAX_PATHS], _path: DynArray[address, MAX_PATHS], _tokenIds: DynArray[uint256, MAX_PATHS], _to: address):
    for i in range(MAX_PATHS-1):
        if i+1 == len(_path):
            break

        amountOut: uint256 = _amounts[i + 1]

        amount0Out: uint256 = 0
        amount1Out: uint256 = 0

        to: address = empty(address)

        token0Index: uint256 = 0
        token1Index: uint256 = 0
        
        nextPair0Index: uint256 = 0
        nextPair1Index: uint256 = 0

        if _tokenIds[i] == 0:
            amount0Out = amountOut
            
            token0Index = i+1
            token1Index = i
            
            nextPair0Index = token0Index
            nextPair1Index = token0Index +1
        else:
            amount1Out = amountOut
            
            token0Index = i
            token1Index = i+1
            
            nextPair0Index = token1Index + 1
            nextPair1Index = token1Index

        currentPair: address = FiveFiveSwapFactory(self.factory).getPair(_path[token0Index], _tokenIds[token0Index], _path[token1Index])

        if i < len(_path) - 2:
            to = FiveFiveSwapFactory(self.factory).getPair(_path[nextPair0Index], _tokenIds[nextPair0Index], _path[nextPair1Index])
        else:
            to = _to 

        FiveFiveSwapPair(currentPair).swap(amount0Out, amount1Out, to, b"")

@internal
def _addLiquidity(
            _tokenA: address, 
            _tokenAId: uint256, 
            _tokenB: address, 
            _amountAdesired: uint256, 
            _amountBdesired: uint256, 
            _amountAMin: uint256, 
            _amountBMin: uint256) -> (uint256, uint256):
    
    pairAddress: address = FiveFiveSwapFactory(self.factory).getPair(_tokenA, _tokenAId, _tokenB)

    if pairAddress == empty(address):
       pairAddress = FiveFiveSwapFactory(self.factory).createPair(_tokenA, _tokenAId, _tokenB)

    reserveA: uint112 = 0
    reserveB: uint112 = 0
    blockTimestampLast: uint32 = 0

    reserveA, reserveB, blockTimestampLast = FiveFiveSwapPair(pairAddress).getReserves()

    amountA: uint256 = 0
    amountB: uint256 = 0

    if reserveA == 0 and reserveB == 0:
        amountA = _amountAdesired
        amountB = _amountBdesired
    else:
        amountBOptimal: uint256 = self._quote(_amountAdesired, reserveA, reserveB)

        if amountBOptimal <= _amountBdesired:
            assert amountBOptimal >= _amountBMin, "FiveFiveRouter: INSUFFICIENT_B_AMOUNT"
            
            amountA = _amountAdesired
            amountB = amountBOptimal
        else:
            amountAOptimal: uint256 = self._quote(_amountBdesired, reserveB, reserveA)
            assert amountAOptimal <= _amountAdesired, "FiveFiveRouter: INSUFFICIENT_A_AMOUNT"
            assert amountAOptimal >= _amountAMin, "FiveFiveRouter: INSUFFICIENT_A_AMOUNT"
            
            amountA = amountAOptimal
            amountB = _amountBdesired

    return amountA, amountB

@internal
def _removeLiquidity(
        _tokenA: address,
        _tokenAId: uint256,
        _tokenB: address,
        _liquidity: uint256,
        _amountAMin: uint256,
        _amountBMin: uint256,
        _to: address,
        _deadline: uint256
    ) -> (uint256, uint256):
    assert _deadline >= block.timestamp, "FiveFiveRouter: EXPIRED"

    amountA: uint256 = 0
    amountB: uint256 = 0

    pair: address = FiveFiveSwapFactory(self.factory).getPair(_tokenA, _tokenAId, _tokenB)
    FiveFiveSwapPair(pair).transferFrom(msg.sender, pair, _liquidity)
    amountA, amountB = FiveFiveSwapPair(pair).burn(_to)

    assert amountA >= _amountAMin, "FiveFiveRouter: INSUFFICIENT_A_AMOUNT"
    assert amountB >= _amountBMin, "FiveFiveRouter: INSUFFICIENT_B_AMOUNT"

    return amountA, amountB

@internal
def _removeLiquidityETH(
        _token: address,
        _tokenId: uint256,
        _liquidity: uint256,
        _amountTokenMin: uint256,
        _amountETHMin: uint256,
        _to: address,
        _deadline: uint256
    ) -> (uint256, uint256):
    assert _deadline >= block.timestamp, "FiveFiveRouter: EXPIRED"

    amountToken: uint256 = 0
    amountETH: uint256 = 0

    amountToken, amountETH = self._removeLiquidity(_token, _tokenId, self.weth, _liquidity, _amountTokenMin, _amountETHMin, self, _deadline)
    ERC1155(_token).safeTransferFrom(self, _to, _tokenId, amountToken, ZERO_BYTES)
    IWETH(self.weth).withdraw(amountETH)
    send(_to, amountETH)

    return amountToken, amountETH

@view
@internal
def _reverseArray(_array: DynArray[uint256, MAX_PATHS]) -> DynArray[uint256, MAX_PATHS]:
    _newArray: DynArray[uint256, MAX_PATHS] = []
    arrayLength: uint256 = len(_array)
    
    for i in range(MAX_PATHS+1):
        x: uint256 = convert(MAX_PATHS, uint256) - i
        
        if x >= arrayLength:
            continue

        _newArray.append(_array[x])

    return _newArray

@internal
def _safeTransfer(_token: address, _to: address, amount: uint256) -> bool:
    _response: Bytes[32] = raw_call(
        _token,
        concat(
            0xa9059cbb, # ERC20 transfer selector
            convert(_to, bytes32),
            convert(amount, bytes32)
        ),
        max_outsize=32
    )
    if len(_response) > 0:
        assert convert(_response, bool), "Transfer failed!"
    return True

@internal
def _safeTransferFrom(_token: address, _from: address, _to: address, amount: uint256) -> bool:
    _response: Bytes[32] = raw_call(
        _token,
        concat(
            0x23b872dd, # ERC20 transfer selector
            convert(_from, bytes32),
            convert(_to, bytes32),
            convert(amount, bytes32)
        ),
        max_outsize=32
    )
    if len(_response) > 0:
        assert convert(_response, bool), "Transfer failed!"
    return True

@external
def addLiquidity(
        _tokenA: address,
        _tokenAId: uint256,
        _tokenB: address,
        _amountADesired: uint256,
        _amountBDesired: uint256,
        _amountAMin: uint256,
        _amountBMin: uint256,
        _to: address,
        _deadline: uint256
    ) -> (uint256, uint256, uint256):
    
    assert _deadline >= block.timestamp, "FiveFiveRouter: EXPIRED"

    amountA: uint256 = 0
    amountB: uint256 = 0

    amountA, amountB = self._addLiquidity(_tokenA, _tokenAId, _tokenB, _amountADesired, _amountBDesired, _amountAMin, _amountBMin)
    pair: address = FiveFiveSwapFactory(self.factory).getPair(_tokenA, _tokenAId, _tokenB)
    ERC1155(_tokenA).safeTransferFrom(msg.sender, pair, _tokenAId, amountA, ZERO_BYTES)
    self._safeTransferFrom(_tokenB, msg.sender, pair, amountB)
    liquidity: uint256 = FiveFiveSwapPair(pair).mint(_to)

    return amountA, amountB, liquidity

@external
@payable
def addLiquidityETH(
        _token: address,
        _tokenId: uint256,
        _amountTokenDesired: uint256,
        _amountTokenMin: uint256,
        _amountETHMin: uint256,
        _to: address,
        _deadline: uint256
    ) -> (uint256, uint256, uint256):

    assert _deadline >= block.timestamp, "FiveFiveRouter: EXPIRED"

    amountToken: uint256 = 0
    amountETH: uint256 = 0

    amountToken, amountETH = self._addLiquidity(_token, _tokenId, self.weth, _amountTokenDesired, msg.value, _amountTokenMin, _amountETHMin)
    pair: address = FiveFiveSwapFactory(self.factory).getPair(_token, _tokenId, self.weth)
    ERC1155(_token).safeTransferFrom(msg.sender, pair, _tokenId, amountToken, ZERO_BYTES)
    IWETH(self.weth).deposit(value=amountETH)

    assert IWETH(self.weth).transfer(pair, amountETH)
    liquidity: uint256 = FiveFiveSwapPair(pair).mint(_to)

    if msg.value > amountETH:
        send(msg.sender, msg.value - amountETH)

    return amountToken, amountETH, liquidity

@external
@nonpayable
def removeLiquidity(
        _tokenA: address,
        _tokenAId: uint256,
        _tokenB: address,
        _liquidity: uint256,
        _amountAMin: uint256,
        _amountBMin: uint256,
        _to: address,
        _deadline: uint256
    ) -> (uint256, uint256):
    return self._removeLiquidity(_tokenA, _tokenAId, _tokenB, _liquidity, _amountAMin, _amountBMin, _to, _deadline)

@external
@payable
def removeLiquidityETH(
        _token: address,
        _tokenId: uint256,
        _liquidity: uint256,
        _amountTokenMin: uint256,
        _amountETHMin: uint256,
        _to: address,
        _deadline: uint256
    ) -> (uint256, uint256):
    return self._removeLiquidityETH(_token, _tokenId, _liquidity, _amountTokenMin, _amountETHMin, _to, _deadline)

@external
@nonpayable
def removeLiquidityWithPermit(
        _tokenA: address,
        _tokenAId: uint256,
        _tokenB: address,
        _liquidity: uint256,
        _amountAMin: uint256,
        _amountBMin: uint256,
        _to: address,
        _deadline: uint256,
        _approveMax: bool,
        _v: uint8,
        _r: bytes32,
        _s: bytes32
    ) -> (uint256, uint256):
    pair: address = FiveFiveSwapFactory(self.factory).getPair(_tokenA, _tokenAId, _tokenB)

    amountA: uint256 = 0
    amountB: uint256 = 0

    value: uint256 = _liquidity

    if _approveMax:
        value = MAX_INT

    FiveFiveSwapPair(pair).permit(msg.sender, self, value, _deadline, _v, _r, _s)
    amountA, amountB = self._removeLiquidity(_tokenA, _tokenAId, _tokenB, _liquidity, _amountAMin, _amountBMin, _to, _deadline)

    return amountA, amountB
    
@external
@nonpayable
def removeLiquidityETHWithPermit(
        _token: address,
        _tokenId: uint256,
        _liquidity: uint256,
        _amountTokenMin: uint256,
        _amountETHMin: uint256,
        _to: address,
        _deadline: uint256,
        _approveMax: bool,
        _v: uint8,
        _r: bytes32,
        _s: bytes32
    ) -> (uint256, uint256):
    pair: address = FiveFiveSwapFactory(self.factory).getPair(_token, _tokenId, self.weth)

    amountToken: uint256 = 0
    amountETH: uint256 = 0

    value: uint256 = _liquidity

    if _approveMax:
        value = MAX_INT

    FiveFiveSwapPair(pair).permit(msg.sender, self, value, _deadline, _v, _r, _s)
    amountToken, amountETH = self._removeLiquidityETH(_token, _tokenId, _liquidity, _amountTokenMin, _amountETHMin, _to, _deadline)

    return amountToken, amountETH


@external
@nonpayable
def swapExactTokensForTokens(
        _amountIn: uint256,
        _amountOutMin: uint256,
        _path: DynArray[address, MAX_PATHS],
        _tokenIds: DynArray[uint256, MAX_PATHS],
        _to: address,
        _deadline: uint256
    ) -> DynArray[uint256, MAX_PATHS]:
    assert _deadline >= block.timestamp, "FiveFiveRouter: EXPIRED"
    amounts: DynArray[uint256, MAX_PATHS] = self._getAmountsOut(_amountIn, _path, _tokenIds)
    assert amounts[len(amounts) - 1] >= _amountOutMin, "FiveFiveRouter: INSUFFICIENT_OUTPUT_AMOUNT"

    if _tokenIds[0] == 0:
        pair: address = FiveFiveSwapFactory(self.factory).getPair(_path[1], _tokenIds[1], _path[0])
        self._safeTransferFrom(_path[0], msg.sender, pair, amounts[0])
    else:
        pair: address = FiveFiveSwapFactory(self.factory).getPair(_path[0], _tokenIds[0], _path[1])
        ERC1155(_path[0]).safeTransferFrom(msg.sender, pair, _tokenIds[0], amounts[0], ZERO_BYTES)

    self._swap(amounts, _path, _tokenIds, _to)

    return amounts

@external
@nonpayable
def swapTokensForExactTokens(
        _amountOut: uint256,
        _amountInMax: uint256,
        _path: DynArray[address, MAX_PATHS],
        _tokenIds: DynArray[uint256, MAX_PATHS],
        _to: address,
        _deadline: uint256
    ) -> DynArray[uint256, MAX_PATHS]:
    assert _deadline >= block.timestamp, "FiveFiveRouter: EXPIRED"
    amounts: DynArray[uint256, MAX_PATHS] = self._getAmountsIn(_amountOut, _path, _tokenIds)
    amounts = self._reverseArray(amounts)

    assert amounts[0] <= _amountInMax, "FiveFiveRouter: EXCESSIVE_INPUT_AMOUNT"

    if _tokenIds[0] == 0:
        pair: address = FiveFiveSwapFactory(self.factory).getPair(_path[1], _tokenIds[1], _path[0])
        self._safeTransferFrom(_path[0], msg.sender, pair, amounts[0])
    else:
        pair: address = FiveFiveSwapFactory(self.factory).getPair(_path[0], _tokenIds[0], _path[1])
        ERC1155(_path[0]).safeTransferFrom(msg.sender, pair, _tokenIds[0], amounts[0], ZERO_BYTES)

    self._swap(amounts, _path, _tokenIds, _to)

    return amounts

@external
@payable
def swapExactETHForTokens(
        _amountOutMin: uint256,
        _path: DynArray[address, MAX_PATHS],
        _tokenIds: DynArray[uint256, MAX_PATHS],
        _to: address,
        _deadline: uint256
    ) -> DynArray[uint256, MAX_PATHS]:
    assert _deadline >= block.timestamp, "FiveFiveRouter: EXPIRED"
    assert _path[0] == self.weth, "FiveFiveRouter: INVALID_PATH"

    amounts: DynArray[uint256, MAX_PATHS] = self._getAmountsOut(msg.value, _path, _tokenIds)

    assert amounts[len(amounts) - 1] >= _amountOutMin, "FiveFiveRouter: INSUFFICIENT_OUTPUT_AMOUNT"
    IWETH(self.weth).deposit(value=amounts[0])
    pair: address = FiveFiveSwapFactory(self.factory).getPair(_path[1], _tokenIds[1], _path[0])
    assert IWETH(self.weth).transfer(pair, amounts[0])

    self._swap(amounts, _path, _tokenIds, _to)

    return amounts

@external
@nonpayable
def swapTokensForExactETH(
        _amountOut: uint256,
        _amountInMax: uint256,
        _path: DynArray[address, MAX_PATHS],
        _tokenIds: DynArray[uint256, MAX_PATHS],
        _to: address,
        _deadline: uint256
    ) -> DynArray[uint256, MAX_PATHS]:
    assert _deadline >= block.timestamp, "FiveFiveRouter: EXPIRED"
    assert _path[len(_path)-1] == self.weth, "FiveFiveRouter: INVALID_PATH"

    amounts: DynArray[uint256, MAX_PATHS] = self._getAmountsIn(_amountOut, _path, _tokenIds)
    amounts = self._reverseArray(amounts)
    assert amounts[0] <= _amountInMax, "FiveFiveRouter: EXCESSIVE_INPUT_AMOUNT"

    if _tokenIds[0] == 0:
        pair: address = FiveFiveSwapFactory(self.factory).getPair(_path[1], _tokenIds[1], _path[0])
        self._safeTransferFrom(_path[0], msg.sender, pair, amounts[0])
    else:
        pair: address = FiveFiveSwapFactory(self.factory).getPair(_path[0], _tokenIds[0], _path[1])
        ERC1155(_path[0]).safeTransferFrom(msg.sender, pair, _tokenIds[0], amounts[0], ZERO_BYTES)

    self._swap(amounts, _path, _tokenIds, self)

    IWETH(self.weth).withdraw(amounts[len(amounts)-1])
    send(_to, amounts[len(amounts)-1])

    return amounts


@external
@nonpayable
def swapExactTokensForETH(
        _amountIn: uint256,
        _amountOutMin: uint256,
        _path: DynArray[address, MAX_PATHS],
        _tokenIds: DynArray[uint256, MAX_PATHS],
        _to: address,
        _deadline: uint256
    ) -> DynArray[uint256, MAX_PATHS]:
    assert _deadline >= block.timestamp, "FiveFiveRouter: EXPIRED"
    assert _path[len(_path)-1] == self.weth, "FiveFiveRouter: INVALID_PATH"

    amounts: DynArray[uint256, MAX_PATHS] = self._getAmountsOut(_amountIn, _path, _tokenIds)
    assert amounts[len(amounts)-1] >= _amountOutMin, "FiveFiveRouter: INSUFFICIENT_OUTPUT_AMOUNT"

    if _tokenIds[0] == 0:
        pair: address = FiveFiveSwapFactory(self.factory).getPair(_path[1], _tokenIds[1], _path[0])
        self._safeTransferFrom(_path[0], msg.sender, pair, amounts[0])
    else:
        pair: address = FiveFiveSwapFactory(self.factory).getPair(_path[0], _tokenIds[0], _path[1])
        ERC1155(_path[0]).safeTransferFrom(msg.sender, pair, _tokenIds[0], amounts[0], ZERO_BYTES)

    self._swap(amounts, _path, _tokenIds, self)

    IWETH(self.weth).withdraw(amounts[len(amounts)-1])
    send(_to, amounts[len(amounts)-1])

    return amounts

@external
@payable
def swapETHForExactTokens(
        _amountOut: uint256,
        _path: DynArray[address, MAX_PATHS],
        _tokenIds: DynArray[uint256, MAX_PATHS],
        _to: address,
        _deadline: uint256
    ) -> DynArray[uint256, MAX_PATHS]:
    assert _deadline >= block.timestamp, "FiveFiveRouter: EXPIRED"
    assert _path[0] == self.weth, "FiveFiveRouter: INVALID_PATH"

    amounts: DynArray[uint256, MAX_PATHS] = self._getAmountsIn(_amountOut, _path, _tokenIds)
    amounts = self._reverseArray(amounts)
    assert amounts[0] <= msg.value, "FiveFiveRouter: EXCESSIVE_INPUT_AMOUNT"
    IWETH(self.weth).deposit(value=amounts[0])
    pair: address = FiveFiveSwapFactory(self.factory).getPair(_path[1], _tokenIds[1], _path[0])
    assert IWETH(self.weth).transfer(pair, amounts[0])

    self._swap(amounts, _path, _tokenIds, _to)

    if msg.value > amounts[0]:
        send(msg.sender, msg.value-amounts[0])

    return amounts

@external
@view
def quote(
        _amountA: uint256,
        _reserveA: uint112,
        _reserveB: uint112
    ) -> uint256:
    return self._quote(_amountA, _reserveA, _reserveB)

@external
@view
def getAmountOut(
        _amountIn: uint256,
        _reserveIn: uint112,
        _reserveOut: uint112
    ) -> uint256:
    return self._getAmountOut(_amountIn, _reserveIn, _reserveOut)

@external
@view
def getAmountIn(
        _amountOut: uint256,
        _reserveIn: uint112,
        _reserveOut: uint112
    ) -> uint256:
    return self._getAmountIn(_amountOut, _reserveIn, _reserveOut)


@external
@view
def getAmountsOut(
        _amountIn: uint256,
        _path: DynArray[address, MAX_PATHS],
        _tokenIds: DynArray[uint256, MAX_PATHS]
    ) -> DynArray[uint256, MAX_PATHS]:
    return self._getAmountsOut(_amountIn, _path, _tokenIds)

@external
@view
def getAmountsIn(
        _amountOut: uint256,
        _path: DynArray[address, MAX_PATHS],
        _tokenIds: DynArray[uint256, MAX_PATHS]
    ) -> DynArray[uint256, MAX_PATHS]:
    return self._reverseArray(self._getAmountsIn(_amountOut, _path, _tokenIds))