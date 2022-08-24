/**
 *Submitted for verification at Etherscan.io on 2022-08-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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

interface ICheck {
    function checkTorch(address _address, uint256 _amount, string memory signedMessage) external view returns (bool);

    function checkGetProp(address _address,uint256[] memory _tokenId,uint256[] memory _amounts,string memory signedMessage) external view returns (bool);
}

interface IMonsterWallet {
    function transferFrozenToken() external;
}

contract MonsterBattleTorch is Ownable{
    IMonsterWallet public MonsterWallet;
    IERC20 public Torch;
    IERC1155 public Storage;
    ICheck private Check;


    bool public _isActiveRecharge = true;
    bool public _isActiveWithdrawal = true;
    bool public _isActiveReceive = true; 

    address token = 0xd33B79F237508251e5740c5229f2c8Ea47Ee30C8;
    address walletAddress = 0xd1c2809f12D74E691769A6C865E6f0d531a8a36f;
    address public receiver = 0xDAC226421Fe37a1B00A469Cf03Ba5629ef5a3db6;
    address public HoleAddress = 0xB63B32CaD8510572210987f489eD6F7547c0b0b1;


    uint256 maxWithdrawTorch = 300000000 ether;
    uint256 withdrawTimes = 3600;
    uint256 frozenBalance = 1000000000 ether;
    
    
    mapping(address => uint256) private Signature;

    event rechargeTorchEvent(address indexed from,uint256 indexed _amount,uint256 indexed _timestamp); 
    event withdrawTorchEvent(address indexed to,uint256 indexed _amount,uint256 indexed _timestamp); 
    event Synthesis(address indexed to,uint256 indexed _tokenId, uint256 indexed  _amount);
   

    constructor(address _check) {
        Torch = IERC20(token);
        Check = ICheck(_check);
        MonsterWallet = IMonsterWallet(walletAddress);
    }

    function rechargeTorch(uint256 _amount) public {
        require(
            _isActiveRecharge,
            "Recharge must be active"
        );

        require(
            _amount > 0,
            "Recharge torch must be greater than 0"
        );

        Torch.transferFrom(msg.sender, address(this), _amount);

        emit rechargeTorchEvent(msg.sender, _amount, block.timestamp);
    }
    

    function withdrawTorch(uint256 _amount, string memory _signature) public {
        require(
            _isActiveWithdrawal,
            "Withdraw must be active"
        );

        require(
            _amount > 0,
            "Withdraw torch must be greater than 0"
        );

        require(
            _amount <= maxWithdrawTorch,
            "Withdraw torch must  be less than max withdraw torch at 1 time"
        );

        require(
            Signature[msg.sender] + withdrawTimes <= block.timestamp,
            "Can only withdraw 1 times at 1 hour"
        );

        require(
            Check.checkTorch(msg.sender, _amount, _signature) == true,
            "Audit error"
        );

        if(Torch.balanceOf(address(this)) <= frozenBalance){
            MonsterWallet.transferFrozenToken();
        }

        require(
            Torch.balanceOf(address(this)) >= _amount,
            "Torch credit is running low"
        );

        Signature[msg.sender] = block.timestamp;

        Torch.transfer( msg.sender, _amount);

        emit withdrawTorchEvent(msg.sender, _amount, block.timestamp);
    }


    function receiveStorage(uint256[] memory _tokenIds,uint256[] memory _amounts,string memory _signature) public{
        require(_isActiveReceive, "Receive storage must be active");

        require(
            Check.checkGetProp(msg.sender, _tokenIds, _amounts, _signature) == true,
            "Audit error"
        );   

        Storage.safeBatchTransferFrom(HoleAddress, msg.sender, _tokenIds, _amounts, "0x00");

        uint256  tokenIdLength  = _tokenIds.length;

        for(uint i = 0;i < tokenIdLength;i++){
            emit Synthesis(msg.sender, _tokenIds[i], _amounts[i]);
        }

    }

    function withdrawToken() public onlyOwner{
        uint256 amount = Torch.balanceOf(address(this));
        Torch.transfer(receiver, amount);
    }

    function setActiveRecharge() public onlyOwner {
        _isActiveRecharge = !_isActiveRecharge;
    }

    function setActiveWithdrawal() public onlyOwner {
        _isActiveWithdrawal = !_isActiveWithdrawal;
    }  

    function setActiveReceive() public onlyOwner {
        _isActiveReceive = !_isActiveReceive;
    }
    
    function setReceiver(address _addr) public onlyOwner{
        receiver = _addr;
    }

    function setHoleAddress(address _addr) public onlyOwner{
        HoleAddress = _addr;
    }


    function setTorchContract(address _addr) public onlyOwner{  
        Torch = IERC20(_addr);
    }

    function setCheckContract(address _addr) public onlyOwner{
        Check = ICheck(_addr);
    }

    function setStorageContract(address _addr) public onlyOwner{
        Storage = IERC1155(_addr);
    }

    function setWalletContract(address _addr) public onlyOwner{
        MonsterWallet = IMonsterWallet(_addr);
    }

    function setMaxWithdrawTorch(uint256 _amount) public onlyOwner{
        maxWithdrawTorch = _amount;
    }

    function setFrozenBalance(uint256 _amount) public onlyOwner{
        frozenBalance = _amount;
    }

    function setWithdrawTimes(uint256 _timestamp) public onlyOwner{
        withdrawTimes = _timestamp;
    }


}