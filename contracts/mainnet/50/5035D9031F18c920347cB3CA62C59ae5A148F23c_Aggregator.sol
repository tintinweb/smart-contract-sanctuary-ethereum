// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11;

import "./MarketRegistry.sol";
import "./libraries/Configable.sol";
import "./libraries/ReentrancyGuard.sol";
import "./libraries/SpecialTransferHelper.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IERC721.sol";
import "./interfaces/IERC1155.sol";

contract Aggregator is SpecialTransferHelper, Configable, ReentrancyGuard {

    struct ERC20Details {
        address[] tokenAddrs;
        uint256[] amounts;
    }

    struct ERC1155Details {
        address tokenAddr;
        uint256[] ids;
        uint256[] amounts;
    }

    struct FeeDetails {
        address recipient;
        uint256 amount;
    }

    struct SendETHParam {
        address to;
        uint256 amount;
    }

    struct SendERC20Param {
        address tokenAddr;
        address to;
        uint256 amount;
    }

    struct SendERC721Param {
        address tokenAddr;
        address to;
        uint256 tokenId;
    }

    struct SendERC1155Param {
        address tokenAddr;
        address to;
        uint256[] ids;
        uint256[] amounts;
    }

    address public converter;
    uint256 public baseFees;
    uint256 public maxFees;
    bool public openForTrades;
    MarketRegistry public marketRegistry;
    MarketRegistry public converterRegistry;
    address public cryptoPunksMarket;
    address public moonCatRescue;

    modifier isOpenForTrades() {
        require(openForTrades, "trades not allowed");
        _;
    }

    constructor(address _marketRegistry, address _converterRegistry) {
        owner = msg.sender;
        marketRegistry = MarketRegistry(_marketRegistry);
        converterRegistry = MarketRegistry(_converterRegistry);
        baseFees = 0;
        openForTrades = true;
    }

    
    function setUp(address _punkProxy, address _cryptoPunksMarket, address _moonCatRescue) external onlyDev {
        // Create CryptoPunk Proxy
        IWrappedPunk(_punkProxy).registerProxy();

        cryptoPunksMarket = _cryptoPunksMarket;
        moonCatRescue = _moonCatRescue;
    }

    // @audit This function is used to approve specific tokens to specific market contracts with high volume.
    // This is done in very rare cases for the gas optimization purposes. 
    function setERC20Approval(IERC20 token, address operator, uint256 amount) external onlyDev {
        token.approve(operator, amount);
    }

    function setERC721Approval(IERC721 token, address operator) external onlyDev {
        token.setApprovalForAll(operator, true);
    }

    function setFees(uint256 _baseFees, uint256 _maxFees) external onlyManager {
        baseFees = _baseFees;
        maxFees = _maxFees;
    }

    function setOpenForTrades(bool _openForTrades) external onlyManager {
        openForTrades = _openForTrades;
    }

    function setConverterRegistry(MarketRegistry _converterRegistry) external onlyDev {
        converterRegistry = _converterRegistry;
    }

    function setMarketRegistry(MarketRegistry _marketRegistry) external onlyDev {
        marketRegistry = _marketRegistry;
    }

    function _transferEth(address _to, uint256 _amount) internal {
        bool callStatus;
        assembly {
            // Transfer the ETH and store if it succeeded or not.
            callStatus := call(gas(), _to, _amount, 0, 0, 0, 0)
        }
        require(callStatus, "_transferEth: Eth transfer failed");
    }

    function _collectFee(FeeDetails[] memory _feeDetails) internal {
        if(_feeDetails.length == 0) return;
        require(_feeDetails[0].amount >= baseFees, "Insufficient base fee");
        require(_feeDetails[0].recipient == team(), "Invalid base recipient");
        uint256 total;
        for(uint256 i; i< _feeDetails.length; i++) {
            total += _feeDetails[i].amount;
            if(_feeDetails[i].amount > 0) {
                _transferEth(_feeDetails[i].recipient, _feeDetails[i].amount);
            }
        }
        require(total <= maxFees, "Over max fee");
    }

    function _checkCallResult(bool _success) internal pure {
        if (!_success) {
            // Copy revert reason from call
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }

    function _transferFromHelper(
        ERC20Details memory erc20Details,
        SpecialTransferHelper.ERC721Details[] memory erc721Details,
        ERC1155Details[] memory erc1155Details
    ) internal {
        // transfer ERC20 tokens from the sender to this contract
        for (uint256 i = 0; i < erc20Details.tokenAddrs.length; i++) {
            (bool success, ) = erc20Details.tokenAddrs[i].call(abi.encodeWithSelector(0x23b872dd, msg.sender, address(this), erc20Details.amounts[i]));
            _checkCallResult(success);
        }

        // transfer ERC721 tokens from the sender to this contract
        for (uint256 i = 0; i < erc721Details.length; i++) {
            // accept CryptoPunksMarket
            if (erc721Details[i].tokenAddr == cryptoPunksMarket) {
                _acceptCryptoPunk(erc721Details[i]);
            }
            // accept MoonCatRescue
            else if (erc721Details[i].tokenAddr == moonCatRescue) {
                _acceptMoonCat(erc721Details[i]);
            }
            // default
            else {
                for (uint256 j = 0; j < erc721Details[i].ids.length; j++) {
                    IERC721(erc721Details[i].tokenAddr).transferFrom(
                        _msgSender(),
                        address(this),
                        erc721Details[i].ids[j]
                    );
                }
            }
        }

        // transfer ERC1155 tokens from the sender to this contract
        for (uint256 i = 0; i < erc1155Details.length; i++) {
            IERC1155(erc1155Details[i].tokenAddr).safeBatchTransferFrom(
                _msgSender(),
                address(this),
                erc1155Details[i].ids,
                erc1155Details[i].amounts,
                ""
            );
        }
    }

    function _conversionHelper(
        MarketRegistry.TradeDetails[] memory _converstionDetails
    ) internal {
        for (uint256 i = 0; i < _converstionDetails.length; i++) {
            (address _proxy, bool _isLib, bool _isActive) = converterRegistry.markets(_converstionDetails[i].marketId);
            // market should be active
            require(_isActive, "_trade: InActive Converter");
            // convert to desired asset
            (bool success, ) = _isLib
                ? _proxy.delegatecall(_converstionDetails[i].tradeData)
                : _proxy.call{value:_converstionDetails[i].value}(_converstionDetails[i].tradeData);
            // check if the call passed successfully
            _checkCallResult(success);
        }
    }

    function _trade(
        MarketRegistry.TradeDetails[] memory _tradeDetails
    ) internal {
        for (uint256 i = 0; i < _tradeDetails.length; i++) {
            // get market details
            (address _proxy, bool _isLib, bool _isActive) = marketRegistry.markets(_tradeDetails[i].marketId);
            // market should be active
            require(_isActive, "_trade: InActive Market");
            // execute trade 
            (bool success, ) = _isLib
                ? _proxy.delegatecall(_tradeDetails[i].tradeData)
                : _proxy.call{value:_tradeDetails[i].value}(_tradeDetails[i].tradeData);
            // check if the call passed successfully
            _checkCallResult(success);
        }
    }

    function _returnDust(address[] memory _tokens) internal {
        // return remaining ETH (if any)
        assembly {
            if gt(selfbalance(), 0) {
                let callStatus := call(
                    gas(),
                    caller(),
                    selfbalance(),
                    0,
                    0,
                    0,
                    0
                )
            }
        }
        // return remaining tokens (if any)
        for (uint256 i = 0; i < _tokens.length; i++) {
            if (IERC20(_tokens[i]).balanceOf(address(this)) > 0) {
                (bool success, ) = _tokens[i].call(abi.encodeWithSelector(0xa9059cbb, msg.sender, IERC20(_tokens[i]).balanceOf(address(this))));
                _checkCallResult(success);
            }
        }
    }
    
    function batchBuyWithETH(
        MarketRegistry.TradeDetails[] memory tradeDetails,
        FeeDetails[] memory feeDetails
    ) payable external isOpenForTrades nonReentrant {
        _collectFee(feeDetails);

        // execute trades
        _trade(tradeDetails);

        // return remaining ETH (if any)
        assembly {
            if gt(selfbalance(), 0) {
                let callStatus := call(
                    gas(),
                    caller(),
                    selfbalance(),
                    0,
                    0,
                    0,
                    0
                )
            }
        }
    }

    function batchBuyWithERC20s(
        ERC20Details memory erc20Details,
        MarketRegistry.TradeDetails[] memory tradeDetails,
        MarketRegistry.TradeDetails[] memory converstionDetails,
        address[] memory dustTokens,
        FeeDetails[] memory feeDetails
    ) payable external isOpenForTrades nonReentrant {
        // transfer ERC20 tokens from the sender to this contract
        for (uint256 i = 0; i < erc20Details.tokenAddrs.length; i++) {
            (bool success, ) = erc20Details.tokenAddrs[i].call(abi.encodeWithSelector(0x23b872dd, msg.sender, address(this), erc20Details.amounts[i]));
            _checkCallResult(success);
        }

        // Convert any assets if needed
        _conversionHelper(converstionDetails);

        _collectFee(feeDetails);

        // execute trades
        _trade(tradeDetails);

        // return dust tokens (if any)
        _returnDust(dustTokens);
    }

    // swaps any combination of ERC-20/721/1155
    // User needs to approve assets before invoking swap
    // WARNING: DO NOT SEND TOKENS TO THIS FUNCTION DIRECTLY!!!
    function multiAssetSwap(
        ERC20Details memory erc20Details,
        SpecialTransferHelper.ERC721Details[] memory erc721Details,
        ERC1155Details[] memory erc1155Details,
        MarketRegistry.TradeDetails[] memory converstionDetails,
        MarketRegistry.TradeDetails[] memory tradeDetails,
        address[] memory dustTokens,
        FeeDetails[] memory feeDetails
    ) payable external isOpenForTrades nonReentrant {
        
        // transfer all tokens
        _transferFromHelper(
            erc20Details,
            erc721Details,
            erc1155Details
        );

        // Convert any assets if needed
        _conversionHelper(converstionDetails);

        // collect fees
        _collectFee(feeDetails);

        // execute trades
        _trade(tradeDetails);

        // return dust tokens (if any)
        _returnDust(dustTokens);
    }

    function batchTransfer(
        SendETHParam[] memory eths,
        SendERC20Param[] memory erc20s,
        SendERC721Param[] memory erc721s,
        SendERC1155Param[] memory erc1155s
    ) payable external isOpenForTrades nonReentrant {
        // transfer ETH
        uint256 value = 0;
        for(uint256 i=0; i < eths.length; i++) {
            value += eths[i].amount;
            _transferEth(eths[i].to, eths[i].amount);
        }

        require(value == msg.value, 'invalid value');

        // transfer ERC20 tokens from the sender to
        for (uint256 i = 0; i < erc20s.length; i++) {
            (bool success, ) = erc20s[i].tokenAddr.call(abi.encodeWithSelector(0x23b872dd, _msgSender(), erc20s[i].to, erc20s[i].amount));
            _checkCallResult(success);
        }

        // transfer ERC721 tokens from the sender to
        for (uint256 i = 0; i < erc721s.length; i++) {
            if (erc721s[i].tokenAddr == cryptoPunksMarket) {
                revert('CryptoPunks is not supported');
            }
            // accept MoonCatRescue
            else if (erc721s[i].tokenAddr == moonCatRescue) {
                revert('MoonCatRescue is not supported');
            }
            // default
            else {
                IERC721(erc721s[i].tokenAddr).transferFrom(
                    _msgSender(),
                    erc721s[i].to,
                    erc721s[i].tokenId
                );
            }
        }

        // transfer ERC1155 tokens from the sender to this contract
        for (uint256 i = 0; i < erc1155s.length; i++) {
            IERC1155(erc1155s[i].tokenAddr).safeBatchTransferFrom(
                _msgSender(),
                erc1155s[i].to,
                erc1155s[i].ids,
                erc1155s[i].amounts,
                ""
            );
        }
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) public virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return 0x150b7a02;
    }

    // Used by ERC721BasicToken.sol
    function onERC721Received(
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return 0xf0b9e5ba;
    }

    function supportsInterface(bytes4 interfaceId)
        external
        virtual
        view
        returns (bool)
    {
        return interfaceId == this.supportsInterface.selector;
    }

    receive() external payable {}

    // Emergency function: In case any ETH get stuck in the contract unintentionally
    // Only owner can retrieve the asset balance to a recipient address
    function rescueETH(address recipient) onlyDev external {
        _transferEth(recipient, address(this).balance);
    }

    // Emergency function: In case any ERC20 tokens get stuck in the contract unintentionally
    // Only owner can retrieve the asset balance to a recipient address
    function rescueERC20(address asset, address recipient) onlyDev external { 
        IERC20(asset).transfer(recipient, IERC20(asset).balanceOf(address(this)));
    }

    // Emergency function: In case any ERC721 tokens get stuck in the contract unintentionally
    // Only owner can retrieve the asset balance to a recipient address
    function rescueERC721(address asset, uint256[] calldata ids, address recipient) onlyDev external {
        for (uint256 i = 0; i < ids.length; i++) {
            IERC721(asset).transferFrom(address(this), recipient, ids[i]);
        }
    }

    // Emergency function: In case any ERC1155 tokens get stuck in the contract unintentionally
    // Only owner can retrieve the asset balance to a recipient address
    function rescueERC1155(address asset, uint256[] calldata ids, uint256[] calldata amounts, address recipient) onlyDev external {
        for (uint256 i = 0; i < ids.length; i++) {
            IERC1155(asset).safeTransferFrom(address(this), recipient, ids[i], amounts[i], "");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.11;


import "./libraries/Configable.sol";

contract MarketRegistry is Configable {

    struct TradeDetails {
        uint256 marketId;
        uint256 value;
        bytes tradeData;
    }

    struct Market {
        address proxy;
        bool isLib;
        bool isActive;
    }

    Market[] public markets;

    constructor(address[] memory proxies, bool[] memory isLibs) {
        owner = msg.sender;
        for (uint256 i = 0; i < proxies.length; i++) {
            markets.push(Market(proxies[i], isLibs[i], true));
        }
    }

    function addMarket(address proxy, bool isLib) external onlyDev {
        markets.push(Market(proxy, isLib, true));
    }

    function setMarketStatus(uint256 marketId, bool newStatus) external onlyDev {
        Market storage market = markets[marketId];
        market.isActive = newStatus;
    }

    function setMarketProxy(uint256 marketId, address newProxy, bool isLib) external onlyDev {
        Market storage market = markets[marketId];
        market.proxy = newProxy;
        market.isLib = isLib;
    }

    function marketsLength() external view returns (uint) {
        return markets.length;
    }

    function getMarkets() external view returns (Market[] memory) {
        return markets;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11;

interface IConfig {
    function dev() external view returns (address);
    function admin() external view returns (address);
    function team() external view returns (address);
}

contract Configable {
    address public config;
    address public owner;

    event ConfigChanged(address indexed _user, address indexed _old, address indexed _new);
    event OwnerChanged(address indexed _user, address indexed _old, address indexed _new);
 
    function setupConfig(address _config) external onlyOwner {
        emit ConfigChanged(msg.sender, config, _config);
        config = _config;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, 'OWNER FORBIDDEN');
        _;
    }

    function admin() public view returns(address) {
        if(config != address(0)) {
            return IConfig(config).admin();
        }
        return owner;
    }

    function dev() public view returns(address) {
        if(config != address(0)) {
            return IConfig(config).dev();
        }
        return owner;
    }

    function team() public view returns(address) {
        if(config != address(0)) {
            return IConfig(config).team();
        }
        return owner;
    }

    function changeOwner(address _user) external onlyOwner {
        require(owner != _user, 'Owner: NO CHANGE');
        emit OwnerChanged(msg.sender, owner, _user);
        owner = _user;
    }
    
    modifier onlyDev() {
        require(msg.sender == dev() || msg.sender == owner, 'dev FORBIDDEN');
        _;
    }
    
    modifier onlyAdmin() {
        require(msg.sender == admin() || msg.sender == owner, 'admin FORBIDDEN');
        _;
    }
  
    modifier onlyManager() {
        require(msg.sender == dev() || msg.sender == admin() || msg.sender == owner, 'manager FORBIDDEN');
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.11;

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private reentrancyStatus = 1;

    modifier nonReentrant() {
        require(reentrancyStatus == 1, "REENTRANCY");

        reentrancyStatus = 2;

        _;

        reentrancyStatus = 1;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.11;

import "./Context.sol";
import "../interfaces/ICryptoPunks.sol";
import "../interfaces/IWrappedPunk.sol";
import "../interfaces/IMoonCatsRescue.sol";

contract SpecialTransferHelper is Context {

    struct ERC721Details {
        address tokenAddr;
        address[] to;
        uint256[] ids;
    }

    function _uintToBytes5(uint256 id)
        internal
        pure
        returns (bytes5 slicedDataBytes5)
    {
        bytes memory _bytes = new bytes(32);
        assembly {
            mstore(add(_bytes, 32), id)
        }

        bytes memory tempBytes;

        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // The first word of the slice result is potentially a partial
            // word read from the original array. To read it, we calculate
            // the length of that partial word and start copying that many
            // bytes into the array. The first word we copy will start with
            // data we don't care about, but the last `lengthmod` bytes will
            // land at the beginning of the contents of the new array. When
            // we're done copying, we overwrite the full first word with
            // the actual length of the slice.
            let lengthmod := and(5, 31)

            // The multiplication in the next line is necessary
            // because when slicing multiples of 32 bytes (lengthmod == 0)
            // the following copy loop was copying the origin's length
            // and then ending prematurely not copying everything it should.
            let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
            let end := add(mc, 5)

            for {
                // The multiplication in the next line has the same exact purpose
                // as the one above.
                let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), 27)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            mstore(tempBytes, 5)

            //update free-memory pointer
            //allocating the array padded to 32 bytes like the compiler does now
            mstore(0x40, and(add(mc, 31), not(31)))
        }

        assembly {
            slicedDataBytes5 := mload(add(tempBytes, 32))
        }
    }


    function _acceptMoonCat(ERC721Details memory erc721Details) internal {
        for (uint256 i = 0; i < erc721Details.ids.length; i++) {
            bytes5 catId = _uintToBytes5(erc721Details.ids[i]);
            address owner = IMoonCatsRescue(erc721Details.tokenAddr).catOwners(catId);
            require(owner == _msgSender(), "_acceptMoonCat: invalid mooncat owner");
            IMoonCatsRescue(erc721Details.tokenAddr).acceptAdoptionOffer(catId);
        }
    }

    function _transferMoonCat(ERC721Details memory erc721Details) internal {
        for (uint256 i = 0; i < erc721Details.ids.length; i++) {
            IMoonCatsRescue(erc721Details.tokenAddr).giveCat(_uintToBytes5(erc721Details.ids[i]), erc721Details.to[i]);
        }
    }

    function _acceptCryptoPunk(ERC721Details memory erc721Details) internal {
        for (uint256 i = 0; i < erc721Details.ids.length; i++) {    
            address owner = ICryptoPunks(erc721Details.tokenAddr).punkIndexToAddress(erc721Details.ids[i]);
            require(owner == _msgSender(), "_acceptCryptoPunk: invalid punk owner");
            ICryptoPunks(erc721Details.tokenAddr).buyPunk(erc721Details.ids[i]);
        }
    }

    function _transferCryptoPunk(ERC721Details memory erc721Details) internal {
        for (uint256 i = 0; i < erc721Details.ids.length; i++) {
            ICryptoPunks(erc721Details.tokenAddr).transferPunk(erc721Details.to[i], erc721Details.ids[i]);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.11;

interface IERC1155 {
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external;

    function balanceOf(address _owner, uint256 _id) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.11;

interface IERC721 {
    /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///  THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) external;
    
    function setApprovalForAll(address operator, bool approved) external;

    function approve(address to, uint256 tokenId) external;
    
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function balanceOf(address _owner) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.11;

interface IERC20 {
    /**
        * @dev Returns the amount of tokens owned by `account`.
        */
    function balanceOf(address account) external view returns (uint256);

    /**
        * @dev Moves `amount` tokens from the caller's account to `recipient`.
        *
        * Returns a boolean value indicating whether the operation succeeded.
        *
        * Emits a {Transfer} event.
        */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.11;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.11;

interface IWrappedPunk {
    /**
     * @dev Mints a wrapped punk
     */
    function mint(uint256 punkIndex) external;

    /**
     * @dev Burns a specific wrapped punk
     */
    function burn(uint256 punkIndex) external;
    
    /**
     * @dev Registers proxy
     */
    function registerProxy() external;

    /**
     * @dev Gets proxy address
     */
    function proxyInfo(address user) external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.11;

interface IMoonCatsRescue {
    function acceptAdoptionOffer(bytes5 catId) payable external;
    function makeAdoptionOfferToAddress(bytes5 catId, uint price, address to) external;
    function giveCat(bytes5 catId, address to) external;
    function catOwners(bytes5 catId) external view returns(address);
    function rescueOrder(uint256 rescueIndex) external view returns(bytes5 catId);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.11;

interface ICryptoPunks {
    function punkIndexToAddress(uint index) external view returns(address owner);
    function offerPunkForSaleToAddress(uint punkIndex, uint minSalePriceInWei, address toAddress) external;
    function buyPunk(uint punkIndex) external payable;
    function transferPunk(address to, uint punkIndex) external;
}