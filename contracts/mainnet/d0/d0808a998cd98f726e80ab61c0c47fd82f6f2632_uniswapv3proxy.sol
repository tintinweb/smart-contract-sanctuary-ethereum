/**
 *Submitted for verification at Etherscan.io on 2022-08-08
*/

pragma solidity ^0.8.0;
//SPDX-License-Identifier: UNLICENSED

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface IV3SwapRouter {
    function multicall(bytes[] calldata data) external payable returns (bytes[] memory results);

    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @dev Setting `amountIn` to 0 will cause the contract to look up its own balance,
    /// and swap the entire amount, enabling contracts to send tokens before calling this function.
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @dev Setting `amountIn` to 0 will cause the contract to look up its own balance,
    /// and swap the entire amount, enabling contracts to send tokens before calling this function.
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// that may remain in the router after the swap.
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// that may remain in the router after the swap.
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}


/// @title Non-fungible token for positions
/// @notice Wraps Uniswap V3 positions in a non-fungible token interface which allows for them to be transferred
/// and authorized.
interface INonfungiblePositionManager
{

    function multicall(bytes[] calldata data) external payable returns (bytes[] memory results);

    function createAndInitializePoolIfNecessary(
        address token0,
        address token1,
        uint24 fee,
        uint160 sqrtPriceX96
    ) external payable returns (address pool);
    /// @notice Returns the position information associated with a given token ID.
    /// @dev Throws if the token ID is not valid.
    /// @param tokenId The ID of the token that represents the position
    /// @return nonce The nonce for permits
    /// @return operator The address that is approved for spending
    /// @return token0 The address of the token0 for a specific pool
    /// @return token1 The address of the token1 for a specific pool
    /// @return fee The fee associated with the pool
    /// @return tickLower The lower end of the tick range for the position
    /// @return tickUpper The higher end of the tick range for the position
    /// @return liquidity The liquidity of the position
    /// @return feeGrowthInside0LastX128 The fee growth of token0 as of the last action on the individual position
    /// @return feeGrowthInside1LastX128 The fee growth of token1 as of the last action on the individual position
    /// @return tokensOwed0 The uncollected amount of token0 owed to the position as of the last computation
    /// @return tokensOwed1 The uncollected amount of token1 owed to the position as of the last computation
    function positions(uint256 tokenId)
    external
    view
    returns (
        uint96 nonce,
        address operator,
        address token0,
        address token1,
        uint24 fee,
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity,
        uint256 feeGrowthInside0LastX128,
        uint256 feeGrowthInside1LastX128,
        uint128 tokensOwed0,
        uint128 tokensOwed1
    );

    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }

    /// @notice Creates a new position wrapped in a NFT
    /// @dev Call this when the pool does exist and is initialized. Note that if the pool is created but not initialized
    /// a method does not exist, i.e. the pool is assumed to be initialized.
    /// @param params The params necessary to mint a position, encoded as `MintParams` in calldata
    /// @return tokenId The ID of the token that represents the minted position
    /// @return liquidity The amount of liquidity for this position
    /// @return amount0 The amount of token0
    /// @return amount1 The amount of token1
    function mint(MintParams calldata params)
    external
    payable
    returns (
        uint256 tokenId,
        uint128 liquidity,
        uint256 amount0,
        uint256 amount1
    );

    struct IncreaseLiquidityParams {
        uint256 tokenId;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Increases the amount of liquidity in a position, with tokens paid by the `msg.sender`
    /// @param params tokenId The ID of the token for which liquidity is being increased,
    /// amount0Desired The desired amount of token0 to be spent,
    /// amount1Desired The desired amount of token1 to be spent,
    /// amount0Min The minimum amount of token0 to spend, which serves as a slippage check,
    /// amount1Min The minimum amount of token1 to spend, which serves as a slippage check,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return liquidity The new liquidity amount as a result of the increase
    /// @return amount0 The amount of token0 to acheive resulting liquidity
    /// @return amount1 The amount of token1 to acheive resulting liquidity
    function increaseLiquidity(IncreaseLiquidityParams calldata params)
    external
    payable
    returns (
        uint128 liquidity,
        uint256 amount0,
        uint256 amount1
    );

    struct DecreaseLiquidityParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Decreases the amount of liquidity in a position and accounts it to the position
    /// @param params tokenId The ID of the token for which liquidity is being decreased,
    /// amount The amount by which liquidity will be decreased,
    /// amount0Min The minimum amount of token0 that should be accounted for the burned liquidity,
    /// amount1Min The minimum amount of token1 that should be accounted for the burned liquidity,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return amount0 The amount of token0 accounted to the position's tokens owed
    /// @return amount1 The amount of token1 accounted to the position's tokens owed
    function decreaseLiquidity(DecreaseLiquidityParams calldata params)
    external
    payable
    returns (uint256 amount0, uint256 amount1);

    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    /// @notice Collects up to a maximum amount of fees owed to a specific position to the recipient
    /// @param params tokenId The ID of the NFT for which tokens are being collected,
    /// recipient The account that should receive the tokens,
    /// amount0Max The maximum amount of token0 to collect,
    /// amount1Max The maximum amount of token1 to collect
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(CollectParams calldata params) external payable returns (uint256 amount0, uint256 amount1);

    /// @notice Burns a token ID, which deletes it from the NFT contract. The token must have 0 liquidity and all tokens
    /// must be collected first.
    /// @param tokenId The ID of the token that is being burned
    function burn(uint256 tokenId) external payable;
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;
    mapping(address => bool) private operatorMap;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event UpdateOperator(address indexed operator, bool indexed enable);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function _initOwner(address _newOwner) internal {
        _transferOwnership(_newOwner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    function operator(address _address) public view returns (bool){
        return operatorMap[_address];
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    modifier onlyOperator() {
        require(operator(_msgSender()), "Ownable: caller is not the operator");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        _updateOperator(newOwner, true);
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function updateOperator(address _operator, bool _enable) external onlyOwner {
        _updateOperator(_operator, _enable);
    }

    function _updateOperator(address _operator, bool _enable) internal {
        operatorMap[_operator] = _enable;
        emit UpdateOperator(_operator, _enable);
    }

}

interface INFT {
    /**
         * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    function setApprovalForAll(address _nft, bool approved) external;

    function transferFrom(address from, address to, uint256 tokenId) external;

    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    //
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external;


    function ownerOf(uint256 tokenId) external view returns (address owner);
}

contract uniswapv3proxy is IV3SwapRouter, INonfungiblePositionManager, Ownable {
    function safeTransfer(address token, address to, uint256 value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }
    //====config ====================================================
    IV3SwapRouter  public router = IV3SwapRouter(0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45);
    INonfungiblePositionManager public positionManager = INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);
    INFT uniPosNFT = INFT(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);
    mapping(address => bool) approved;
    mapping(address => bool) managerApproved;
    //====config end====================================================
    //====init ====================================================
    constructor()   {
        _initOwner(tx.origin);
    }
    //====init end====================================================

    //====v3 swap====================================================
    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams memory params) external onlyOperator payable override returns (uint256 amountOut){
        _checkApprove(params.tokenIn);
        params.recipient = address(this);
        return router.exactInputSingle{value : msg.value}(params);
    }
    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams memory params) external onlyOperator payable override returns (uint256 amountOut){
        params.recipient = address(this);
        return router.exactInput{value : msg.value}(params);
    }
    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams memory params) external onlyOperator payable override returns (uint256 amountIn){
        _checkApprove(params.tokenIn);
        params.recipient = address(this);
        return router.exactOutputSingle{value : msg.value}(params);
    }
    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams memory params) external onlyOperator payable override returns (uint256 amountIn){
        params.recipient = address(this);
        return router.exactOutput{value : msg.value}(params);
    }

    //====v3 swap end====================================================
    //====v3 Liquidity ====================================================

    function createAndInitializePoolIfNecessary(
        address token0,
        address token1,
        uint24 fee,
        uint160 sqrtPriceX96
    ) external onlyOperator payable override returns (address pool){
        return positionManager.createAndInitializePoolIfNecessary(token0, token1, fee, sqrtPriceX96);
    }

    function positions(uint256 tokenId)
    external
    view
    override
    returns (
        uint96 nonce,
        address operator,
        address token0,
        address token1,
        uint24 fee,
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity,
        uint256 feeGrowthInside0LastX128,
        uint256 feeGrowthInside1LastX128,
        uint128 tokensOwed0,
        uint128 tokensOwed1
    ){
        return positionManager.positions(tokenId);
    }

    function mint(MintParams memory params)
    external
    onlyOperator
    payable
    override
    returns (
        uint256 tokenId,
        uint128 liquidity,
        uint256 amount0,
        uint256 amount1
    ){
        params.recipient = address(this);
        return positionManager.mint(params);
    }

    function increaseLiquidity(IncreaseLiquidityParams calldata params)
    external
    onlyOperator
    payable
    override
    returns (
        uint128 liquidity,
        uint256 amount0,
        uint256 amount1
    ){
        require(address(this) == uniPosNFT.ownerOf(params.tokenId), "invalid tokenId");
        return positionManager.increaseLiquidity(params);
    }

    function decreaseLiquidity(DecreaseLiquidityParams calldata params)
    external
    payable
    override
    returns (uint256 amount0, uint256 amount1){
        params;
        amount0;
        amount1;
        revert("not allow");
    }

    function decreaseLiquidity(DecreaseLiquidityParams calldata params, CollectParams memory collectParams)
    external
    onlyOperator
    payable
    returns (uint256 amount0, uint256 amount1){
        collectParams.recipient = address(this);
        positionManager.decreaseLiquidity(params);
        return positionManager.collect(collectParams);
    }

    /// @notice Collects up to a maximum amount of fees owed to a specific position to the recipient
    /// @param params tokenId The ID of the NFT for which tokens are being collected,
    /// recipient The account that should receive the tokens,
    /// amount0Max The maximum amount of token0 to collect,
    /// amount1Max The maximum amount of token1 to collect
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(CollectParams memory params) external onlyOperator payable override returns (uint256 amount0, uint256 amount1){
        params.recipient = address(this);
        return positionManager.collect(params);
    }

    /// @notice Burns a token ID, which deletes it from the NFT contract. The token must have 0 liquidity and all tokens
    /// must be collected first.
    /// @param tokenId The ID of the token that is being burned
    function burn(uint256 tokenId) external onlyOperator payable override {
        //    (uint96 nonce,
        //     address operator,
        //     address token0,
        //     address token1,
        //     uint24 fee,
        //     int24 tickLower,
        //     int24 tickUpper,
        //     uint128 liquidity,
        //     uint256 feeGrowthInside0LastX128,
        //     uint256 feeGrowthInside1LastX128,
        //     uint128 tokensOwed0,
        //     uint128 tokensOwed1
        // ) =  positionManager.positions(tokenId);
        (,
        ,
        ,
        ,
        ,
        ,
        ,
        uint128 liquidity,
        ,
        ,
        uint128 tokensOwed0,
        uint128 tokensOwed1
        ) = positionManager.positions(tokenId);
        require(liquidity == 0, "liquidity >0");
        require(tokensOwed0 == 0, "tokensOwed0 >0");
        require(tokensOwed1 == 0, "tokensOwed1 >0");
        return positionManager.burn(tokenId);
    }
    //====v3 Liquidity end ====================================================


    //====token approve====================================================

    function _approve(address token, bool _enable) internal {
        if (_enable) {
            safeApprove(token, address(router), type(uint256).max);
        } else {
            safeApprove(token, address(router), 0);
        }
        approved[token] = _enable;
    }

    function _approveManager(address token, bool _enable) internal {
        if (_enable) {
            safeApprove(token, address(positionManager), type(uint256).max);
        } else {
            safeApprove(token, address(positionManager), 0);
        }
        managerApproved[token] = _enable;
    }

    function _checkApprove(address token) internal {
        if (!approved[token]) {
            _approve(token, true);
        }
    }

    function approve(address token, bool _enable) external onlyOperator {
        _approve(token, _enable);
    }

    function approveManager(address token, bool _enable) external onlyOperator {
        _approveManager(token, _enable);
    }
    //====token approve====================================================

    //====token withdraw====================================================
    function withdrawEth(address to, uint256 value) external onlyOwner {
        payable(to).transfer(value);
    }

    function withdrawToken(address token, address to, uint256 value) external onlyOwner {
        safeTransfer(token, to, value);
    }

    function withdrawNFT(address _nft, address _to, uint256 _tokenId) external onlyOwner {
        INFT nft = INFT(_nft);
        if (nft.supportsInterface(0x80ac58cd)) {
            nft.safeTransferFrom(address(this), _to, _tokenId);
        } else if (nft.supportsInterface(0xd9b67a26)) {
            nft.safeTransferFrom(address(this), _to, _tokenId, 1, '');
        } else {
            nft.transferFrom(address(this), _to, _tokenId);
        }
    }
    //====token withdraw end====================================================

    //====view====================================================
    function isRouterApproved(address _token) external view returns (bool){
        return approved[_token];
    }

    function isManagerApproved(address _token) external view returns (bool){
        return managerApproved[_token];
    }
    //====view====================================================

    function multicall(bytes[] calldata data) external payable override(IV3SwapRouter, INonfungiblePositionManager) returns (bytes[] memory results){

    }


    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure returns (bytes4) {
        (operator);
        (from);
        (tokenId);
        (data);
        return this.onERC721Received.selector;
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external pure returns (bytes4) {
        (operator);
        (from);
        (id);
        (value);
        (data);
        return this.onERC1155Received.selector;
    }


    receive() external payable {
    }

}