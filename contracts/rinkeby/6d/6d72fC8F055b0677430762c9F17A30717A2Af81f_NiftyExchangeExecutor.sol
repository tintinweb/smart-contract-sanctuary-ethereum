// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

interface IERC1155 {
    function balanceOf(address _owner, uint256 _id) external view returns (uint256);
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external;
}

interface IERC721 {
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) external payable;
}

interface INiftyRegistry {
    function isOwner(address recoverer) external view returns (bool);
    function isValidNiftySender(address sending_key) external view returns (bool);
}

/**
 * @dev The purpose of this data structure is to mitigate the 'Stack too deep' error,
 * caused by passing all requisite values as individual parameters.
 * @dev For sales recorded in ETH, the price will be specified in units of wei. 
 *
 * @notice In on-platform sales the 'buyer' and 'seller' addresses correspond to the 
 * address registered to the user's Nifty Gateway account. In the case that the user
 * hasn't registered an address the Nifty Gateway 'omnibus' address will be provided.  
 */
struct NiftyEvent {
    string currency;
    uint256 price; 
    uint256 tokenId;
    uint256 count; /// @notice Value of `0` indicates ERC-721 token
    address tokenContract;
    address buyer; 
    address seller;
    bytes data;
}

/**
 *
 */
contract NiftyExchangeExecutor {

    address immutable public _registry;
    
    uint8 constant public _one = 1;
    
    bool public _locked = false;

    event NiftySale(string currency, uint256 price, uint256 tokenId, uint256 count, address indexed tokenContract);

    constructor(address registry_) {
        _registry = registry_;
    }

    /**
     * @dev Enforce account authorization.
     */
    modifier onlyValidSender() {
        require(INiftyRegistry(_registry).isValidNiftySender(msg.sender), "NiftyExchangeExecutor: Invalid sender");
        _;
    }

    modifier onlyValidOwner() {
        require(INiftyRegistry(_registry).isOwner(msg.sender), "NiftyExchangeExecutor: Invalid owner");
        _;
    }

    modifier notLocked() {
        require(!_locked, "NiftyExchangeExecutor: Lock engaged");
        _;
    }

    function lock() external onlyValidSender returns (bool locked) {
        _locked = true;
        return _locked;
    }

    function unlock() external onlyValidOwner returns (bool locked) {
        _locked = false;
        return _locked;
    }

    /**
     * @dev Logs a NiftySale event in the case of an on-platform sale. 
     */
    function recordSale(NiftyEvent calldata niftyEvent) external onlyValidSender notLocked {
        _recordSale(niftyEvent);
    }

    /**
     * @dev Gas efficient mechanism to logs a series of NiftySale events for on-platform sales. The
     * backend application accumulates sale events and broadcasts them on a schedule, or once the max-
     * imum threshold has been reached, as established by the block gas limit of 30000000.
     *
     * @notice The time that the sale took place is implicit in the block that the `NiftySale` events
     * are triggered in. 
     */
    function recordSaleBatch(NiftyEvent[] calldata niftyEvent) external onlyValidSender notLocked {
        for (uint256 i = 0; i < niftyEvent.length; i++) {
            _recordSale(niftyEvent[i]);
        }
    }

    /**
     * @dev Internal function, localizing the functionality called by the above two methods.
     */
    function _recordSale(NiftyEvent calldata niftyEvent) private {
        if(niftyEvent.count == 0) {
            emit NiftySale(niftyEvent.currency, niftyEvent.price, niftyEvent.tokenId, _one, niftyEvent.tokenContract);
            return;
        }
        emit NiftySale(niftyEvent.currency, niftyEvent.price, niftyEvent.tokenId, niftyEvent.count, niftyEvent.tokenContract);
    }

    /**
     * @dev Singular transfer and NiftySale event, with significant 'data' parameter.  
     */
    function executeSale(NiftyEvent calldata niftyEvent) external onlyValidSender notLocked {     
        _executeSale(niftyEvent);
    }

    /**
     * @dev Gas efficient mechanism to execute a series of NiftySale events with corresponding token transfers.
     */
    function executeSaleBatch(NiftyEvent[] calldata niftyEvent) external onlyValidSender notLocked {     
        for (uint256 i = 0; i < niftyEvent.length; i++) {
            _executeSale(niftyEvent[i]);
        }
    }

    /**
     * @dev Internal function, localizing the functionality called by the above two methods.
     */
    function _executeSale(NiftyEvent calldata niftyEvent) private {     
        if(niftyEvent.count == 0) {
            IERC721(niftyEvent.tokenContract).safeTransferFrom(niftyEvent.seller, niftyEvent.buyer, niftyEvent.tokenId, niftyEvent.data);
            emit NiftySale(niftyEvent.currency, niftyEvent.price, niftyEvent.tokenId, _one, niftyEvent.tokenContract);
            return;
        }
        IERC1155(niftyEvent.tokenContract).safeTransferFrom(niftyEvent.seller, niftyEvent.buyer, niftyEvent.tokenId, niftyEvent.count, niftyEvent.data);
        emit NiftySale(niftyEvent.currency, niftyEvent.price, niftyEvent.tokenId, niftyEvent.count, niftyEvent.tokenContract); /// @notice `price` describes entire purchase.
    }

    /**
     * @dev Facilitates transfer to a smartcontract that doesn't implement 'IERC721Receiver.onERC721Received'.
     */
    function executeSaleUnsafe721(NiftyEvent calldata niftyEvent) external onlyValidSender notLocked {
        require(niftyEvent.count == 0, "NiftyExchangeExecutor: ERC-721 requires count of 0 on NiftyEvent");
        IERC721(niftyEvent.tokenContract).transferFrom(niftyEvent.seller, niftyEvent.buyer, niftyEvent.tokenId);
        emit NiftySale(niftyEvent.currency, niftyEvent.price, niftyEvent.tokenId, _one, niftyEvent.tokenContract);
    }

    /**
     * @dev Convenience method(s) to recover accidentally allocated assets.
     */
    function withdraw(address payable recipient) external onlyValidSender notLocked {
        (bool success,) = recipient.call{value: address(this).balance}("");
        require(success, "NiftyExchangeExecutor: Withdraw unsuccessful");
    }

    function withdraw20(address tokenContract, address recipient) external onlyValidSender notLocked {
        uint256 amount = IERC20(tokenContract).balanceOf(address(this));
        IERC20(tokenContract).transfer(recipient, amount);
    }

    function withdraw721(address tokenContract, address recipient, uint256 tokenId) external onlyValidSender notLocked {
        IERC721(tokenContract).transferFrom(address(this), recipient, tokenId);
    }

}