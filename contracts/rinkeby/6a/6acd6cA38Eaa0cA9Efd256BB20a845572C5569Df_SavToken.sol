/**
 *Submitted for verification at Etherscan.io on 2022-09-11
*/

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

interface SavNonFungible{
  function isAddressEmployed(address _addressToCheck) external returns(bool);
}

contract Verifying {
    function getMessageHash(
        address _account,
        uint _amount,
        string memory _message,
        uint _nonce
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_account, _amount, _message, _nonce));
    }

    function getEthSignedMessageHash(bytes32 _messageHash)
        public
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash)
            );
    }

    function verify(
        address _signer,
        address _account,
        uint _amount,
        string memory _message,
        uint _nonce,
        bytes memory signature
    ) public pure returns (bool) {
        bytes32 messageHash = getMessageHash(_account, _amount, _message, _nonce);
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
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }
}

contract SavToken is Ownable, Verifying{
  event EventBurn(address indexed _from, uint _value, string _data);
  event EventMint(address indexed _to, uint _value);

  mapping(address => uint256) private _balances;
  mapping(uint256 => bool) private nonces;

  address private _addressNFT;
  address private signAddress;

  uint256 private _totalSupply;

  string private _name;
  string private _symbol;


  constructor(string memory name_, string memory symbol_, address addressNFT_, address signAddress_) {
      _name = name_;
      _symbol = symbol_;
      changeAddressNFT(addressNFT_);
      setSignAddress(signAddress_);
  }

  function name() public view returns (string memory) {
      return _name;
  }

  function symbol() public view returns (string memory) {
      return _symbol;
  }

  function decimals() public pure returns (uint8) {
      return 18;
  }


  function balanceOf(address account) public view returns (uint256) {
      return _balances[account];
  }

  function changeAddressNFT(address newAddress) public onlyOwner{
    _addressNFT = newAddress;
  }

  function setSignAddress(address _signAddress) public onlyOwner{
        signAddress = _signAddress;
    }

  function mintTo(address account, uint256 amount) external onlyOwner {
      require(account != address(0), "Mint to the zero address");

      _totalSupply += amount;
      _balances[account] += amount;

      emit EventMint(account, amount);
  }

  function burnAndBuy(uint amount, string memory _data, uint256 _nonce, bytes memory _signature) external{
    address account = _msgSender();

    SavNonFungible nfToken = SavNonFungible(_addressNFT);
    require(nfToken.isAddressEmployed(account), "Address owner is not employed");

    uint256 accountBalance = _balances[account];
    require(accountBalance >= amount, "Burn amount exceeds balance");
    
    require(nonces[_nonce] == false, "Signature already used");
    require(verify(signAddress, account, amount, _data, _nonce, _signature), "Invalid signature!");

    nonces[_nonce] = true;
    unchecked {
      _balances[account] = accountBalance - amount;
    }
    _totalSupply -= amount;

    emit EventBurn(account, amount, _data);
  }
}