// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

enum ItemType {
    ERC20,
    ERC721,
    ERC1155,
    OTHER
}
/**
for a put option, here are the things we need to do:
// seller placing order
1. seller set up a put option by locking ETH to the contract
2. buyer pay the ETH to buy the put option contract

//buyer placing order 
1. buyer sign a request for WETH
2. seller can take the request by locking ETH and take WETH as fee
3. verify the signature
    a. check if signature valid
    b. check if signature expired

// executing contract 
1. buyer can execute the contract by sending the NFT to seller and get the ETH locked in the contract

// modify contract
1. seller can adjust the contract anytime he wants as long as no one is buying the contract
2. seller can also withdraw the fund anytime

// sign order
1. provide a sign otder method to make signature
*/

error PutOption__InsufficientFund();
error PutOption__ContractNotAvailable();
error PutOption__AssetNotSupported();

contract PutNFTOption is Ownable {



    // Config for the smart contract
    // Todo WETH_ADDRESS
    address public S_WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    uint256 public s_contractCommission = 25; // 2.5%
    bytes4 public constant ERC1155InterfaceId = 0xd9b67a26;
    bytes4 public constant ERC721InterfaceId = 0x80ac58cd;
    mapping(address => bool) public s_whitelistedAddresses; 

    // 1. get available contract 
    OptionContract[] public s_allContracts;

    // 2. get finished contract 
    uint256[] public s_finishedcontractIDs; 


    // 3. get contract by user address
    //    store all contract finishedcontractIDs when exercised, deactivated
    //    get the length of all finishedcontractIDs
    //    loop the array to get the IDs
    mapping(address => uint256[]) public s_contractIDToHost;

    // store the cancelled and fulfilled signature
    mapping(bytes => bool) public s_invalidSignatures; 

    // EVENETS 
    event ContractCreated(uint contractID, address host, address nftAddr);
    event BuyContract(uint contractID, address player);
    event ContractExercised(uint contractID, uint nftID);
    event ContractDeactivated(uint contractID);


    struct OptionContract { 
    
        bool active;
        bool exercised;
        ItemType itemType;
        
        address seller;
        address buyer;

        Order order;

        uint256 totalIncome;
        uint256 ethBalance;
        
    }
    struct Order{
        address nftAddr; 
        uint256 strikePrice; 
        uint256 premium; 
        uint256 duration;
        uint256 expieryDate;
    }

    constructor (address[] memory _addressesToWhitelist) {

        for (uint256 index = 0; index < _addressesToWhitelist.length; index++) {
            require(s_whitelistedAddresses[_addressesToWhitelist[index]] != true, "Address is already whitlisted");
            s_whitelistedAddresses[_addressesToWhitelist[index]] = true;
        }        
    }


    function getInterfaceType(address _nft) public view returns (ItemType) {
        IERC165 _thisNFT = IERC165(_nft);
        if (_thisNFT.supportsInterface(ERC1155InterfaceId)) 
            return ItemType.ERC1155;
        else if (_thisNFT.supportsInterface(ERC721InterfaceId))
            return ItemType.ERC721;
        else 
            return ItemType.OTHER;
    } 
    
    // when nft owner deposit nft and setup the machine, return capsule ID
    /**
    * input ETH to set up a put contract
    * seller agree to buy an NFT at the strike price anytime the buyer want
    */
    function setUpContract(address _assetAddress, uint256 _strikePrice, uint256 _premium, uint256 _duration) 
        external payable
        returns (uint256 contractID)
    {   
        // check whitelisted nft
        if(isAddressWhitelisted(_assetAddress) != true) revert PutOption__AssetNotSupported();
        // require(isAddressWhitelisted(_assetAddress) == true, "Asset Address isn't whitelisted");

        // check user input enough money
        // deposit ETH to contract
        if(msg.value < (_strikePrice)) revert PutOption__InsufficientFund(); //0x4ff1292f
        uint256 _paidAmt = msg.value;
        // require(msg.value >= _strikePrice, "Insufficient fund");

        // check owner if ERC 721 or ERC 1155
        ItemType _nftType = getInterfaceType(_assetAddress);
        if(_nftType == ItemType.OTHER) revert PutOption__AssetNotSupported();

        return fulfillSetupContract(_assetAddress, _strikePrice, _premium, _duration, _paidAmt);
    }


    // when nft owner deposit nft and setup the machine, return capsule ID
    /**
    * input ETH to set up a put contract
    * seller agree to buy an NFT at the strike price anytime the buyer want
    */
    function fulfillSetupContract(address _assetAddress, uint256 _strikePrice, uint256 _premium, uint256 _duration, uint256 _paidAmt) 
        internal
        returns (uint256 contractID)
    {   
        // check whitelisted nft
        if(isAddressWhitelisted(_assetAddress) != true) revert PutOption__AssetNotSupported();

        // check user input enough money
        // deposit ETH to contract
        if(_paidAmt < (_strikePrice)) revert PutOption__InsufficientFund(); //0x4ff1292f

        // check owner if ERC 721 or ERC 1155
        ItemType _nftType = getInterfaceType(_assetAddress);
        if(_nftType == ItemType.OTHER) revert PutOption__AssetNotSupported();

        // setup contract info
        uint256 _newContractID = s_allContracts.length;
        OptionContract memory c; 
        c.seller = tx.origin;
        c.active = true;
        c.itemType = _nftType;
        Order memory order;
        c.order = order;
        c.order.duration = _duration;

        // set it to expired
        c.order.expieryDate = block.timestamp;
        c.order.nftAddr = _assetAddress;
        c.order.strikePrice = _strikePrice;
        c.order.premium = _premium;

        s_contractIDToHost[tx.origin].push(_newContractID);
        // numberOfContract[tx.origin] = numberOfContract[tx.origin]+1;

        s_allContracts.push(c);

        emit ContractCreated(_newContractID, tx.origin, _assetAddress);

        return _newContractID;
    }



    function getNumberOfContractPerAddress(address _owner) public view returns (uint256 num){
        return s_contractIDToHost[_owner].length;
    }

    // player buys capsule partition
    function buyContract(uint256 _contractID) public payable
    {
        if(isContractAvailable(_contractID) != true) revert PutOption__ContractNotAvailable();

        OptionContract storage c = s_allContracts[_contractID];
        if(msg.value < c.order.premium) revert PutOption__InsufficientFund();

        c.buyer = tx.origin;
        c.totalIncome += msg.value;
        c.ethBalance += msg.value;
        c.order.expieryDate = c.order.duration + block.timestamp;

        emit BuyContract(_contractID, tx.origin);
    }

    function modifyContract(uint256 _contractID, uint256 _duration, uint256 _strikePrice, uint256 _premium) public payable{
        require(isContractAvailable(_contractID) == true, "Contract is not available.");
        OptionContract storage c = s_allContracts[_contractID];
        if(c.order.strikePrice > _strikePrice){
            uint256 withdrawAmt = c.order.strikePrice - _strikePrice;
            (bool success1, ) = (address(c.seller)).call{value: withdrawAmt }("");
            require(success1, "withdraw failed.");
        }else{
            uint256 despositAmt =  _strikePrice - c.order.strikePrice;
            if(msg.value < (despositAmt)) revert PutOption__InsufficientFund();
        }
        c.order.duration = _duration;
        c.order.strikePrice = _strikePrice;
        c.order.premium = _premium;
    }

    function deactivateContract(uint256 _contractID) public{
        if(isContractAvailable(_contractID) != true) revert PutOption__ContractNotAvailable();
        OptionContract storage c = s_allContracts[_contractID];
        require (tx.origin == c.seller, "not contract owner.");
        // deactivate
        c.active = false;

        // withdraw the collected fee 
        if(c.ethBalance > 0){
            uint256 commission = c.ethBalance * s_contractCommission/1000;
            uint256 withdrawAmt = c.ethBalance - commission;
            (bool success1, ) = (address(c.seller)).call{value: withdrawAmt }("");
            require(success1, "withdraw failed.");
            c.ethBalance  = 0;
            (bool success2, ) = owner().call{value: commission }("");
            require(success2, "withdraw commission failed.");
        }

        (bool success3, ) = (address(c.seller)).call{value: c.order.strikePrice }("");
        require(success3, "withdraw failed.");
        s_finishedcontractIDs.push(_contractID);

        emit ContractDeactivated(_contractID);
    }

    // withdraw only the fee
    function sellerWithdrawFund(uint256 _contractID) external {
        require(isContractExist(_contractID), "contract does not exist.");
        OptionContract storage c = s_allContracts[_contractID];
        require(msg.sender == c.seller, "only for seller");
        require(c.ethBalance > 0, "no available fund for withdraw.");

        // transfer fund (only the collected fee)
        uint256 commission = c.ethBalance * s_contractCommission/1000;
        uint256 withdrawAmt = c.ethBalance - commission;
        (bool success1, ) = (address(c.seller)).call{value: withdrawAmt}("");
        require(success1, "withdraw failed.");
        c.ethBalance  = 0;
        (bool success2, ) = owner().call{value: commission }("");
        require(success2, "withdraw commission failed.");
    }
    

    function cancelOffer(address _assetAddress, uint256 _strikePrice, uint256 _premium, uint256 _duration, address _buyer, uint256 _effectiveDate, bytes32 _salt,
    bytes memory _signature) public{
        
        bool verified = verify(_buyer, _assetAddress, _strikePrice, _premium, _duration, _effectiveDate, _salt, _signature);
        require(verified == true, "wrong signature!");
        require(_buyer == tx.origin, "this is not your offer!");
        
        s_invalidSignatures[_signature] = true;
    }


    function fulfillOrder(address _assetAddress, uint256 _strikePrice, uint256 _premium, uint256 _duration, address _buyer, uint256 _effectiveDate, bytes32 _salt,
    bytes memory _signature) public payable{
        
        //check if order valid
        require(_effectiveDate > block.timestamp, "offer expired!");
        bool verified = verify(_buyer, _assetAddress, _strikePrice, _premium, _duration, _effectiveDate, _salt, _signature);
        require(verified == true, "wrong signature!");
        require(s_invalidSignatures[_signature] != true, "offer not available.");

        if(msg.value < (_strikePrice)) revert PutOption__InsufficientFund(); //0x4ff1292f
        uint256 _paidAmt = msg.value;
        
        //stored the fulfilled 
        s_invalidSignatures[_signature] = true;
        
        // send ETH function inside the contract
        uint256 _contractID = fulfillSetupContract(_assetAddress,  _strikePrice,  _premium,  _duration,  _paidAmt);

        // ERC20 funciton, transfer WETH
        uint256 commission = _premium * s_contractCommission/1000;
        uint256 withdrawAmt = _premium - commission;
        IERC20 _weth = IERC20(S_WETH_ADDRESS);
        _weth.transferFrom(_buyer, tx.origin, withdrawAmt);
        _weth.transferFrom(_buyer, address(owner()), commission);


        OptionContract storage c = s_allContracts[_contractID];
        c.buyer = _buyer;
        c.totalIncome += _premium;
        // update the expieryDate of the option contract
        c.order.expieryDate = c.order.duration + block.timestamp;

        emit BuyContract(_contractID, _buyer);

    }
    

    function exerciseContract(uint256 _contractID, uint256 _nftID) public returns(bool){
        if (_contractID < 0 || _contractID >= s_allContracts.length) 
            return false;
        OptionContract storage c = s_allContracts[_contractID];
        require (tx.origin == c.buyer, "not contract buyer.");
        require (c.order.expieryDate > block.timestamp, "contract expired");
        
        // deavtivate
        c.active = false;
        c.exercised =  true;

        // buyer sell NFT to seller
        if (c.itemType == ItemType.ERC1155){
            IERC1155 _thisNft = IERC1155(c.order.nftAddr);
            _thisNft.safeTransferFrom(c.buyer, c.seller, _nftID, 1, "");
            // withdraw ERC1155
        }
        if (c.itemType == ItemType.ERC721){
            IERC721 _thisNFT = IERC721(c.order.nftAddr);
            _thisNFT.safeTransferFrom(c.buyer, c.seller, _nftID);
            // withdraw ERC721
        }

        //sending unclaimed balance to 
        uint256 commission = (c.ethBalance) * s_contractCommission/1000;
        uint256 withdrawAmt = (c.ethBalance) - commission;
        c.ethBalance  = 0;
        (bool success1, ) = owner().call{value: commission }("");
        require(success1, "seller transfer commission failed.");
        (bool success2, ) = (address(c.seller)).call{value: withdrawAmt}("");
        require(success2, "seller withdraw failed.");

        //sending the strike price ETH in contract to buyer

        uint256 strikeCommission = (c.order.strikePrice) * s_contractCommission/1000;
        uint256 strikeAmt = (c.order.strikePrice) - strikeCommission;

        (bool success3, ) = (address(c.buyer)).call{value: strikeAmt}("");
        require(success3, "buyer withdraw failed.");
        (bool success4, ) = owner().call{value: strikeCommission }("");
        require(success4, "buyer transfer commission failed.");
        
        s_finishedcontractIDs.push(_contractID);
        emit ContractExercised(_contractID, _nftID);
        return true;
    }



    function isContractExist(uint256 _contractId) public view returns (bool) {
        if (_contractId < 0 || _contractId >= s_allContracts.length) 
            return false;

        return true;
    }


    function isContractAvailable(uint256 _contractId) public view returns (bool) {
        require(isContractExist(_contractId), "contract does not exist.");
        OptionContract memory c = s_allContracts[_contractId];
        if (c.exercised != true && c.active == true && c.order.expieryDate < block.timestamp)
            return true;

        return false;
    }

    // function getCapsuleJackpotNum(uint _contractId) public view
    //     returns (uint resultNum)
    // {
    //     require(isContractExist(_contractId), "capsule not exist.");
    //     Capsule memory c = allCapsules[_contractId];
    //     return c.jackpotNum;
    // }

    function getContractDetail(uint256 _contractId) public view
    returns(uint256, bool, bool, ItemType, address, address, address, uint256, uint256, uint256, uint256)
    {
        require(isContractExist(_contractId), "contract does not exist.");
        OptionContract memory c = s_allContracts[_contractId];
        return (
            // c.contractID,
            _contractId,
            c.active,
            c.exercised,
            c.itemType,

            c.seller,
            c.buyer,

            c.order.nftAddr, 

            c.order.strikePrice, 
            c.order.premium, 
            c.order.duration,
            c.order.expieryDate
        );
    }
    

    function getContractIncome(uint256 _contractId) public view
    returns(uint256, uint256, uint256)
    {
        require(isContractExist(_contractId), "contract does not exist.");
        OptionContract memory c = s_allContracts[_contractId];
        return (
            // c.contractID,
            _contractId,
            c.totalIncome,
            c.ethBalance
        );
    }
    
    
    function getContractNum() public view returns (uint256) 
    {
        return s_allContracts.length;
    }

    function getFinishedContractNum() public view returns (uint256) 
    {
        return s_finishedcontractIDs.length;
    }

    function getFinishedContractID(uint256 index) public view returns (uint256) 
    {
        return s_finishedcontractIDs[index];
    }

    function isAddressWhitelisted(address _whitelistedAddress) public view returns(bool) {
        return s_whitelistedAddresses[_whitelistedAddress] == true;
    }

    function addAddressesToWhitelist(address[] memory _addressesToWhitelist) public onlyOwner {
        for (uint256 index = 0; index < _addressesToWhitelist.length; index++) {
            require(s_whitelistedAddresses[_addressesToWhitelist[index]] != true, "Address is already whitlisted");
            s_whitelistedAddresses[_addressesToWhitelist[index]] = true;
        }        
    }

    function removeAddressesFromWhitelist(address[] memory _addressesToRemove) public onlyOwner {
        for (uint256 index = 0; index < _addressesToRemove.length; index++) {
            require(s_whitelistedAddresses[_addressesToRemove[index]] == true, "Address isn't whitelisted");
            s_whitelistedAddresses[_addressesToRemove[index]] = false;
        }
    }

    
    
    // not applying for now
    // function flipOnlyWhitelist() public onlyOwner {
    //     _onlyWhitelisted = !_onlyWhitelisted;
    // }

    function editContractCommission(uint256 _newAmt) external onlyOwner {
        s_contractCommission = _newAmt;
    }



    function kill() external onlyOwner {
        selfdestruct(payable(address(owner())));
    }

    //this contract is not supposed to receive any NFT, this function is an emergency exit if someone accidentally deposited their NFT
    function emergencyNFTExit(address _assetAddress, uint256 _tokenId) external onlyOwner{
        // check owner if ERC 721 or ERC 1155
        ItemType _nftType = getInterfaceType(_assetAddress);
        require(_nftType != ItemType.OTHER, "Asset is not a recognizable type of NFT");
        // deposit nft
        if (_nftType == ItemType.ERC721) {
            IERC721 _thisNFT = IERC721(_assetAddress);
            _thisNFT.transferFrom(address(this), address(owner()), _tokenId);
        } else if (_nftType == ItemType.ERC1155) {
            IERC1155 _thisNFT = IERC1155(_assetAddress);
            _thisNFT.safeTransferFrom(address(this), address(owner()), _tokenId, 1, "");
        }

    }



    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }




    // code for signature and verification
    function getMessageHash(address _assetAddress, uint256 _strikePrice, uint256 _premium, uint256 _duration, uint256 _effectiveDate, bytes32 salt)public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_assetAddress, _strikePrice, _premium, _duration, _effectiveDate, salt));
    }

    function getEthSignedMessageHash(bytes32 _messageHash)
        public
        pure
        returns (bytes32)
    {
        /*
        Signature is produced by signing a keccak256 hash with the following format:
        "\x19Ethereum Signed Message\n" + len(msg) + msg
        */
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash)
            );
    }


    //verify the signed messaged
    function verify(
        address _signer,
        address _assetAddress, uint256 _strikePrice, uint256 _premium, uint256 _duration, uint256 _effectiveDate, bytes32 salt,
        bytes memory signature
    ) public pure returns (bool) {
        bytes32 messageHash = getMessageHash(_assetAddress, _strikePrice, _premium, _duration, _effectiveDate, salt);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recoverSigner(ethSignedMessageHash, signature) == _signer;
    }

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature)
        public
        pure
        returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
        public
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }
        // implicitly return (r, s, v)
    }

    function setWETHAddress(address _wethAdddress) public {
        S_WETH_ADDRESS = _wethAdddress;
    }
}


// todo: review and remove all unnecessary comment

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
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
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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