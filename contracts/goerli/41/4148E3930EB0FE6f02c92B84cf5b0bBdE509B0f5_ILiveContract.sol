/**
 *Submitted for verification at Etherscan.io on 2022-11-23
*/

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT
interface IERC20 {
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

abstract contract VerifySignature {
    function getMessageHash(
        address _to,
        uint256 _packageId,
        uint256 _userId,
        uint256 _amount,
        uint256 _nonce
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(_to, _packageId, _userId, _amount, _nonce)
            );
    }

    function getEthSignedMessageHash(bytes32 _messageHash)
        public
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _messageHash
                )
            );
    }

    function verifySignature(
        address _signer,
        address _to,
        uint256 _packageId,
        uint256 _userId,
        uint256 _amount,
        uint256 _nonce,
        bytes memory _signature
    ) public pure returns (bool) {
        bytes32 messageHash = getMessageHash(
            _to,
            _packageId,
            _userId,
            _amount,
            _nonce
        );
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recoverSigner(ethSignedMessageHash, _signature) == _signer;
    }

    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) public pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory _sig)
        public
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(_sig.length == 65, "invalid signature length");
        assembly {
            r := mload(add(_sig, 32))
            s := mload(add(_sig, 64))
            v := byte(0, mload(add(_sig, 96)))
        }
    }
}

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)
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

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)
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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

abstract contract OwnerOperator is Ownable {
    mapping(address => bool) public operators;

    constructor() Ownable() {}

    modifier operatorOrOwner() {
        require(
            operators[msg.sender] || owner() == msg.sender,
            "OwnerOperator: !operator, !owner"
        );
        _;
    }

    modifier onlyOperator() {
        require(operators[msg.sender], "OwnerOperator: !operator");
        _;
    }

    function addOperator(address operator) external virtual onlyOwner {
        require(
            operator != address(0),
            "OwnerOperator: operator is the zero address"
        );
        operators[operator] = true;
    }

    function removeOperator(address operator) external virtual onlyOwner {
        require(
            operator != address(0),
            "OwnerOperator: operator is the zero address"
        );
        operators[operator] = false;
    }
}

contract ILiveContract is VerifySignature, OwnerOperator {
    address public erc20Address;
    address public adminReceiver;
    address public signerAddress;

    constructor(
        address _erc20Address,
        address _adminReceiver,
        address _signerAddress,
        address _operatorAddress
    ) {
        erc20Address = _erc20Address;
        adminReceiver = _adminReceiver;
        signerAddress = _signerAddress;
        operators[_operatorAddress];
    }

    event Transfer(
        uint256 packageId,
        uint256 amount,
        address walletAddress,
        uint256 userId
    );

    function setERC20Address(address _address) external onlyOperator {
        require(_address != address(0x0), "Address must be different 0x0");
        erc20Address = _address;
    }

    function setAdminReceiver(address _address) external onlyOperator {
        require(_address != address(0x0), "Address must be different 0x0");
        adminReceiver = _address;
    }

    function setSignerAddress(address _address) external onlyOperator {
        require(_address != address(0x0), "Address must be different 0x0");
        signerAddress = _address;
    }

    function transferByWalletUser(
        uint256 packageId,
        uint256 userId,
        uint256 amount,
        uint256 nonce,
        bytes memory signature
    ) external {
        address sender = msg.sender;

        require(
            verifySignature(
                signerAddress,
                sender,
                packageId,
                userId,
                amount,
                nonce,
                signature
            ),
            "Verify signature fail"
        );

        IERC20 erc20Token = IERC20(erc20Address);

        require(
            erc20Token.allowance(sender, address(this)) >= amount,
            "Allowance insuffice"
        );
        require(erc20Token.balanceOf(sender) >= amount, "Insuffice balance");

        erc20Token.transferFrom(sender, adminReceiver, amount);

        emit Transfer(packageId, amount, sender, userId);
    }

    /**
        @dev withdraw native token
        @param amount uint256
     */
    function withdraw(uint256 amount) external onlyOwner {
        require(address(this).balance >= amount, "Insufficient balance");
        payable(msg.sender).transfer(amount);
    }

    /**
        @dev withdraw erc20 token
        @param tokenAddress address
        @param amount uint256
     */
    function withdrawToken(address tokenAddress, uint256 amount)
        external
        onlyOwner
    {
        IERC20 erc20Token = IERC20(tokenAddress);
        require(
            erc20Token.balanceOf(address(this)) >= amount,
            "Insufficient balance"
        );
        erc20Token.transfer(msg.sender, amount);
    }
}