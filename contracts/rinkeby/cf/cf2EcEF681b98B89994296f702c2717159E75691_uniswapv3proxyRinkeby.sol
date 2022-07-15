pragma solidity ^0.8.0;
//SPDX-License-Identifier: UNLICENSED
import "./IV3SwapRouter.sol";
import "./IERC20.sol";
import "./INonfungiblePositionManager.sol";
import "./Initializable.sol";

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
}

contract uniswapv3proxyRinkeby is IV3SwapRouter, INonfungiblePositionManager, Ownable, Initializable {
    function safeTransfer(address token, address to, uint256 value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }
    //====config ====================================================
    IV3SwapRouter  router = IV3SwapRouter(0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45);
    mapping(address => bool) approved;
    INonfungiblePositionManager positionManager = INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);
    mapping(address => bool) managerApproved;
    //====config end====================================================
    //====init ====================================================
    function init() public initializer {
        router = IV3SwapRouter(0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45);
        _initOwner(tx.origin);
        init1();
    }
    //
    function init1() public {
        positionManager = INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);
    }
    //====init end====================================================

    //====v3 swap====================================================
    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams memory params) external onlyOperator payable returns (uint256 amountOut){
        _checkApprove(params.tokenIn);
        params.recipient = address(this);
        return router.exactInputSingle{value : msg.value}(params);
    }
    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams memory params) external onlyOperator payable returns (uint256 amountOut){
        params.recipient = address(this);
        return router.exactInput{value : msg.value}(params);
    }
    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams memory params) external onlyOperator payable returns (uint256 amountIn){
        _checkApprove(params.tokenIn);
        params.recipient = address(this);
        return router.exactOutputSingle{value : msg.value}(params);
    }
    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams memory params) external onlyOperator payable returns (uint256 amountIn){
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
    returns (
        uint128 liquidity,
        uint256 amount0,
        uint256 amount1
    ){
        return positionManager.increaseLiquidity(params);
    }

    function decreaseLiquidity(DecreaseLiquidityParams calldata params)
    external
    onlyOperator
    payable
    returns (uint256 amount0, uint256 amount1){

        return positionManager.decreaseLiquidity(params);
    }

    function decreaseLiquidity2(DecreaseLiquidityParams calldata params, CollectParams memory collectParams)
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
    function collect(CollectParams memory params) external onlyOperator payable returns (uint256 amount0, uint256 amount1){
        params.recipient = address(this);
        return positionManager.collect(params);
    }

    /// @notice Burns a token ID, which deletes it from the NFT contract. The token must have 0 liquidity and all tokens
    /// must be collected first.
    /// @param tokenId The ID of the token that is being burned
    function burn(uint256 tokenId) external onlyOperator payable {
        return positionManager.burn(tokenId);
    }
    //====v3 Liquidity end ====================================================


    //====token approve====================================================

    function _approve(address token, bool _enable) internal {
        if (_enable) {
            IERC20(token).approve(address(router), type(uint256).max);
        } else {
            IERC20(token).approve(address(router), 0);
        }
        approved[token] = _enable;
    }

    function _approveManager(address token, bool _enable) internal {
        if (_enable) {
            IERC20(token).approve(address(positionManager), type(uint256).max);
        } else {
            IERC20(token).approve(address(positionManager), 0);
        }
        managerApproved[token] = _enable;
    }

    function _approveNFT(address token, bool _enable) internal {
        if (_enable) {
            INFT(token).setApprovalForAll(address(positionManager), _enable);
        } else {
            INFT(token).setApprovalForAll(address(positionManager), _enable);
        }
        approved[token] = _enable;
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

    function setApprovalForAll(address _nft, bool _approved) external onlyOperator {
        _approveNFT(_nft, _approved);
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

    function isNftApproved(address _token) external view returns (bool){
        return approved[_token];
    }
    //====view====================================================

    function multicall(bytes[] calldata data) external payable override(IV3SwapRouter, INonfungiblePositionManager) returns (bytes[] memory results){

    }
//
//    function multicallManager(bytes[] calldata data) external payable returns (bytes[] memory results){
//        return positionManager.multicall(data);
//    }
//
//    function multicallRouter(bytes[] calldata data) external payable returns (bytes[] memory results){
//        return router.multicall(data);
//    }


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