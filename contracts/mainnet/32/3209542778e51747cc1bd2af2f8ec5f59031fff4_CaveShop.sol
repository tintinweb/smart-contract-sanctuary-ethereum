/**
 *Submitted for verification at Etherscan.io on 2022-09-07
*/

/**
 *Submitted for verification at Etherscan.io on 2022-08-22
*/

// SPDX-License-Identifier: MIT

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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/token/ERC1155/IERC1155.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}



pragma solidity ^0.8.4;





contract CaveShop is Ownable {

    IERC1155 public tokenA;
    IERC20 public tokenB;
    IERC20 public tokenC;

   
    address public initial;

    address public DivideReceiver = 0xeE7513e1cFf5aE8b6f18F68Dd6Ef908e577CC68f;
    address constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address public specialAddress = 0xfAe2ac6097A334777c0901DC49adc65483096029;

    uint256 public DEADFee = 60;

    uint256[] private commodityTokenId; 
    mapping(uint256 => uint256) private commodityPrice;  

    uint256[] private luxuryCommodityTokenId;  
    mapping(uint256 => uint256) private luxuryCommodityPrice;  

    mapping(uint256 => bool) private special;  

    mapping(uint256 => bool) private upgradePackage;  

    bool public _isCommonStore = true;
    bool public _isCommonSynthesis = true;
    bool public _isEquipmentSynthesis = true;
    bool public _isTimesSwitch = true;

    uint256[2] private businessHours; 

    event Synthesis(address indexed from,uint256 indexed _tokenId, uint256 indexed  _amount, uint256  value);

    constructor(address _tokenA, address _tokenB, address _tokenC) {
        tokenA = IERC1155(_tokenA);
        tokenB = IERC20(_tokenB);
        tokenC = IERC20(_tokenC);
        initial = msg.sender;
    }
    
    function commonStore(uint256[] memory _tokenId,uint256[] memory _amount) public{
        require(_isCommonStore, "stoppage of business");

        uint commodityLength = _tokenId.length;
        uint commodityAmount = _amount.length;
        require(
            commodityLength == commodityAmount,
            "Quantity does not match"
        );
        uint256 priceCount = 0;
        uint256 specialPrice = 0;
        uint256 upgradePrice = 0;
        for(uint i = 0; i < commodityLength; i++){
            require(
            tokenA.balanceOf(initial,_tokenId[i]) >= _amount[i],
            "Insufficient balance"
            );
            require(
            commodityPrice[_tokenId[i]] > 0,
            "no such product"
            );

            if(special[_tokenId[i]]){
               specialPrice +=  commodityPrice[_tokenId[i]] * _amount[i];
            }else if(upgradePackage[_tokenId[i]]){
               upgradePrice +=  commodityPrice[_tokenId[i]] * _amount[i];
            }else{
               priceCount +=  commodityPrice[_tokenId[i]] * _amount[i];
            }
        }

        require(
            tokenB.allowance(msg.sender,address(this)) >= priceCount + specialPrice,
            "insufficient allowance"
        );

        require(
            tokenC.allowance(msg.sender,address(this)) >=  upgradePrice,
            "insufficient allowance"
        );

        require(
            tokenB.balanceOf(msg.sender) >= priceCount + specialPrice,
            "Not enough Torch send"
        );

        require(
            tokenC.balanceOf(msg.sender) >=  upgradePrice,
            "Not enough Torch send"
        );

        uint256 DeadAmount = priceCount * DEADFee / 10 ** 2;
        uint256 divideAmount = priceCount - DeadAmount;

        if(priceCount > 0){
            tokenB.transferFrom(msg.sender, DEAD, DeadAmount);
            tokenB.transferFrom(msg.sender, DivideReceiver, divideAmount);  
        }

        if(specialPrice > 0){
            tokenB.transferFrom(msg.sender, specialAddress, specialPrice);  
        }

        if(upgradePrice > 0){
            tokenC.transferFrom(msg.sender, specialAddress, upgradePrice);  
        }
        tokenA.safeBatchTransferFrom(initial, msg.sender, _tokenId, _amount, "0x00");

    }

    
    function commonSynthesis(uint256[] memory _tokenId,uint256[] memory _amount,uint256 _monsterTokenid) public{
        require(_isCommonSynthesis, "stoppage of business");

        uint commodityLength = _tokenId.length;
        uint commodityAmount = _amount.length;
        require(
            commodityLength == commodityAmount,
            "Quantity does not match"
        );
        uint256 priceCount = 0;
        uint256 specialPrice = 0;
        uint256 upgradePrice = 0;
        for(uint i = 0; i < commodityLength; i++){
            require(
            tokenA.balanceOf(initial,_tokenId[i]) >= _amount[i],
            "Insufficient balance"
            );
            require(
            commodityPrice[_tokenId[i]] > 0,
            "no such product"
            );

            if(special[_tokenId[i]]){
               specialPrice +=  commodityPrice[_tokenId[i]] * _amount[i];
            }else if(upgradePackage[_tokenId[i]]){
               upgradePrice +=  commodityPrice[_tokenId[i]] * _amount[i];
            }else{
               priceCount +=  commodityPrice[_tokenId[i]] * _amount[i];
            }

            emit Synthesis(msg.sender, _tokenId[i], _amount[i],_monsterTokenid);
        }

        require(
            tokenB.allowance(msg.sender,address(this)) >= priceCount + specialPrice,
            "insufficient allowance"
        );

        require(
            tokenC.allowance(msg.sender,address(this)) >=  upgradePrice,
            "insufficient allowance"
        );

        require(
            tokenB.balanceOf(msg.sender) >= priceCount + specialPrice,
            "Not enough Torch send"
        );
        require(
            tokenC.balanceOf(msg.sender) >=  upgradePrice,
            "Not enough Torch send"
        );

        uint256 DeadAmount = priceCount * DEADFee / 10 ** 2;
        uint256 divideAmount = priceCount - DeadAmount;

        if(priceCount > 0){
            tokenB.transferFrom(msg.sender, DEAD, DeadAmount);
            tokenB.transferFrom(msg.sender, DivideReceiver, divideAmount);  
        }

        if(specialPrice > 0){
            tokenB.transferFrom(msg.sender, specialAddress, specialPrice);  
        }

        if(upgradePrice > 0){
            tokenC.transferFrom(msg.sender, specialAddress, upgradePrice);  
        }
        
        tokenA.safeBatchTransferFrom(initial, DEAD, _tokenId, _amount, "0x00");

    }
       
    function luxuryStores(uint256[] memory _tokenId,uint256[] memory _amount) public{
        uint commodityLength = _tokenId.length;
        uint commodityAmount = _amount.length;
        require(
            commodityLength == commodityAmount,
            "Quantity does not match"
        );

        if(_isTimesSwitch){
            require(
                businessHours[0] < block.timestamp  && businessHours[0] + businessHours[1] > block.timestamp,
                "Business hours have not yet come"
            );
        }

        uint256 priceCount = 0;
        for(uint i = 0; i < commodityLength; i++){
            require(
            tokenA.balanceOf(initial,_tokenId[i]) >= _amount[i],
            "Insufficient balance"
            );
            require(
            luxuryCommodityPrice[_tokenId[i]] > 0,
            "no such product"
            );
            priceCount +=  luxuryCommodityPrice[_tokenId[i]] * _amount[i];
        }

        require(
            tokenB.allowance(msg.sender,address(this)) >= priceCount,
            "insufficient allowance"
        );

        require(
            tokenB.balanceOf(msg.sender) >= priceCount,
            "Not enough Torch send"
        );

        uint256 DeadAmount = priceCount * DEADFee / 10 ** 2;
        uint256 divideAmount = priceCount - DeadAmount;

        tokenB.transferFrom(msg.sender, DEAD, DeadAmount);
        tokenB.transferFrom(msg.sender, DivideReceiver, divideAmount);  
        
        tokenA.safeBatchTransferFrom(initial, msg.sender, _tokenId, _amount, "0x00");

    }

    
    function luxuryStoresSynthesis(uint256[] memory _tokenId,uint256[] memory _amount,uint256 _monsterTokenid) public{
        uint commodityLength = _tokenId.length;
        uint commodityAmount = _amount.length;
        require(
            commodityLength == commodityAmount,
            "Quantity does not match"
        );
        if(_isTimesSwitch){
            require(
                businessHours[0] < block.timestamp  && businessHours[0] + businessHours[1] > block.timestamp,
                "Business hours have not yet come"
            );
        }

        uint256 priceCount = 0;
        for(uint i = 0; i < commodityLength; i++){
            require(
            tokenA.balanceOf(initial,_tokenId[i]) >= _amount[i],
            "Insufficient balance"
            );
            require(
            luxuryCommodityPrice[_tokenId[i]] > 0,
            "no such product"
            );
            priceCount +=  luxuryCommodityPrice[_tokenId[i]] * _amount[i];
            emit Synthesis(msg.sender, _tokenId[i], _amount[i],_monsterTokenid);
        }

        require(
            tokenB.allowance(msg.sender,address(this)) >= priceCount,
            "insufficient allowance"
        );

        require(
            tokenB.balanceOf(msg.sender) >= priceCount,
            "Not enough Torch send"
        );

        uint256 DeadAmount = priceCount * DEADFee / 10 ** 2;
        uint256 divideAmount = priceCount - DeadAmount;

        tokenB.transferFrom(msg.sender, DEAD, DeadAmount);
        tokenB.transferFrom(msg.sender, DivideReceiver, divideAmount);  
        
        tokenA.safeBatchTransferFrom(initial, DEAD, _tokenId, _amount, "0x00");

    }
    
    function equipmentSynthesis(uint256[] memory _tokenId,uint256[] memory _amount,uint256 _monsterTokenid) public{
        require(_isEquipmentSynthesis, "stoppage of business");

        uint commodityLength = _tokenId.length;
        uint commodityAmount = _amount.length;
        require(
            commodityLength == commodityAmount,
            "Quantity does not match"
        );
        for(uint i = 0; i < commodityLength; i++){
            require(
            tokenA.balanceOf(msg.sender,_tokenId[i]) >= _amount[i],
            "Insufficient balance"
            );
            emit Synthesis(msg.sender, _tokenId[i], _amount[i],_monsterTokenid);
        }

        tokenA.safeBatchTransferFrom(msg.sender, DEAD, _tokenId, _amount, "0x00");

    }
  
    
    function setUpCommodityPrice(uint256[] memory _tokenId,uint256[] memory _amount) public  onlyOwner {
        uint commodityLength = _tokenId.length;
        uint commodityAmount = _amount.length;
        require(
            commodityLength == commodityAmount,
            "Quantity does not match"
        );

        for(uint i = 0; i < commodityLength; i++){
            commodityPrice[_tokenId[i]] = _amount[i];
            if(!getIsCommodityTokenId(_tokenId[i])){
                commodityTokenId.push(_tokenId[i]);
            }
        }
    }
   
    function getIsCommodityTokenId(uint256 _tokenId) public view returns(bool){
        uint commodityLength = commodityTokenId.length;
        for(uint i = 0; i < commodityLength; i++){
            if(commodityTokenId[i] == _tokenId){
                return true;
            }
        }
        return false;
    }
    
    function getCommodityPriceList() public view returns(uint256[] memory,uint256[] memory){
        uint commodityLength = commodityTokenId.length;
        uint256[] memory allPrice = new uint[](commodityLength);
        uint counter = 0;
        for(uint i = 0; i < commodityLength;i++){
            allPrice[counter] = commodityPrice[commodityTokenId[i]];
            counter++;
        }
        return (commodityTokenId,allPrice);
    }
    
    function setUpLuxuryCommodityPrice(uint256[] memory _tokenId,uint256[] memory _amount) public  onlyOwner {
        uint commodityLength = _tokenId.length;
        uint commodityAmount = _amount.length;
        require(
            commodityLength == commodityAmount,
            "Quantity does not match"
        );

        for(uint i = 0; i < commodityLength; i++){
            luxuryCommodityPrice[_tokenId[i]] = _amount[i];
            if(!getIsLuxuryCommodityTokenId(_tokenId[i])){
                luxuryCommodityTokenId.push(_tokenId[i]);
            }
        }
    }
    
    function getIsLuxuryCommodityTokenId(uint256 _tokenId) public view  returns(bool){
        uint luxuryCommodityLength = luxuryCommodityTokenId.length;
        for(uint i = 0; i < luxuryCommodityLength; i++){
            if(luxuryCommodityTokenId[i] == _tokenId){
                return true;
            }
        }
        return false;
    }
    
    function getLuxuryCommodityPriceList() public view returns(uint256[] memory,uint256[] memory){
        uint luxuryCommodityLength = luxuryCommodityTokenId.length;
        uint256[] memory allPrice = new uint[](luxuryCommodityLength);
        uint counter = 0;
        for(uint i = 0; i < luxuryCommodityLength;i++){
            allPrice[counter] = luxuryCommodityPrice[luxuryCommodityTokenId[i]];
            counter++;
        }
        return (luxuryCommodityTokenId,allPrice);
    }
     
    function getGeneralStorePrice(uint256[] memory _tokenId,uint256[] memory _amount) public view returns(uint256){
        uint commodityLength = _tokenId.length;
        uint commodityAmount = _amount.length;
        require(
            commodityLength == commodityAmount,
            "Quantity does not match"
        );
        uint256 count = 0;
        for(uint i = 0; i < commodityLength; i++){
            count +=  commodityPrice[_tokenId[i]] * _amount[i];
        }
        return count;
    
    }
    
    function getLuxuryGeneralStorePrice(uint256[] memory _tokenId,uint256[] memory _amount) public view returns(uint256){
        uint commodityLength = _tokenId.length;
        uint commodityAmount = _amount.length;
        require(
            commodityLength == commodityAmount,
            "Quantity does not match"
        );
        uint256 count = 0;
        for(uint i = 0; i < commodityLength; i++){
            count +=  luxuryCommodityPrice[_tokenId[i]] * _amount[i];
        }
        return count;
    
    }
    
    function setUpBusinessHours(uint256[] memory _timeDeta) public  onlyOwner {
        businessHours[0] = _timeDeta[0];
        businessHours[1] = _timeDeta[1];
    }  
    
    function getblocktimes() public view returns(uint256) {
        return block.timestamp;
    }   
    
    function flipisCommonStore() public onlyOwner {
        _isCommonStore = !_isCommonStore;
    }
    
    function flipisCommonSynthesis() public onlyOwner {
        _isCommonSynthesis = !_isCommonSynthesis;
    }
    
    function flipisEquipmentSynthesis() public onlyOwner {
        _isEquipmentSynthesis = !_isEquipmentSynthesis;
    }
    
    function flipisTimesSwitch() public onlyOwner {
        _isTimesSwitch = !_isTimesSwitch;
    }
    
    function getBusinessHours() public view returns(uint256[2] memory){
        return businessHours;
    }
    

    function setTokenAContract(address _tokenA) public onlyOwner {
        tokenA = IERC1155(_tokenA);
    }

    function setTokenBContract(address _tokenB) public onlyOwner {
        tokenB = IERC20(_tokenB);
    }
    
    function setTokenCContract(address _tokenC) public onlyOwner {
        tokenC = IERC20(_tokenC);
    }

    function setDivideReceiver(address _address) public onlyOwner {
        DivideReceiver = _address;
    }

   
    function setDEADFee(uint256 _amount) public onlyOwner{
        DEADFee = _amount;
    }

    function setSpecialAddress(address  _addr) public onlyOwner{
       specialAddress = _addr;
    }

    function setSpecial(uint256[] memory  _tokenId,bool[] memory  value) public onlyOwner{
        uint specialLength = _tokenId.length;
        uint specialBool = value.length;

        require(
            specialLength == specialBool,
            "Quantity does not match"
        );

        for(uint i = 0; i < specialLength; i++){
            special[_tokenId[i]] = value[i];
        }
     
    }

    function getSpecial(uint256[] memory _tokenId) public view returns(bool[] memory){
        bool[] memory result = new bool[](_tokenId.length);
        uint counter = 0;
        for (uint i = 0; i < _tokenId.length; i++) {
                result[counter] = special[_tokenId[i]];
                counter++;
        }
       return result;
    }

    function setUpgradePackage(uint256[] memory  _tokenId,bool[] memory  value) public onlyOwner{
        uint upgradeLength = _tokenId.length;
        uint upgradeBool = value.length;

        require(
            upgradeLength == upgradeBool,
            "Quantity does not match"
        );

        for(uint i = 0; i < upgradeLength; i++){
            upgradePackage[_tokenId[i]] = value[i];
        }
     
    }

    function getUpgradePackage(uint256[] memory _tokenId) public view returns(bool[] memory){
        bool[] memory result = new bool[](_tokenId.length);
        uint counter = 0;
        for (uint i = 0; i < _tokenId.length; i++) {
                result[counter] = upgradePackage[_tokenId[i]];
                counter++;
        }
       return result;
    }
 




}