/**
 *Submitted for verification at Etherscan.io on 2022-07-01
*/

// File: contracts/interfaces/ISigners.sol


pragma solidity ^0.8.0;

interface ISignersRepository {
    event SignerAdded(address, address);
    event SignerRemoved(address, address);


    function containsSigner(address) external view returns (bool);
    function containsSigners(address[] calldata) external view returns (bool);
    function signersLength() view external returns (uint256);
    function setupSigner(address) external;
}

// File: contracts/helpers/Ownable.sol


pragma solidity ^0.8.0;

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
// File: contracts/helpers/HashIndexer.sol


pragma solidity ^0.8.0;

abstract contract HashIndexer {
    mapping(string => bool) private hashes;

    event HashAdded(string hash);

    constructor () {}

    modifier onlyInexistentHash(string memory _hash) {
        require(!hashes[_hash], "HashIndexer: such hash already exists");
        _;
    }

    function _addHash(string memory _hash) internal {
        hashes[_hash] = true;
        emit HashAdded(_hash);
    }

    function containsHash(string memory _hash) external view returns (bool){
        return _containsHash(_hash);
    }

    function _containsHash(string memory _hash) internal view returns (bool){
        return hashes[_hash];
    }
}
// File: contracts/interfaces/IERC20.sol



pragma solidity ^0.8.0;

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
    * @dev Returns the token name.
    */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address spender) external view returns (uint256);

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
// File: contracts/handlers/ERC20Handler.sol



pragma solidity ^0.8.0;


abstract contract ERC20Handler {
    function _deriveERC20Signers(
        address _token,
        string memory _txHash,
        uint256 _amount,
        bytes32[] memory _r,
        bytes32[] memory _s,
        uint8[] memory _v
    ) internal view returns (address[] memory) {
        bytes32 _hash = keccak256(abi.encodePacked(block.chainid, _token, msg.sender, _txHash, _amount));
        address[] memory _signers = new address[](_r.length);
        for (uint8 i = 0; i < _r.length; i++) {
            _signers[i] = ecrecover(_hash, _v[i], _r[i], _s[i]);
        }

        return _signers;
    }

    function _sendERC20(
        address _token,
        address _receiver,
        uint256 _amount
    ) internal {
        require(IERC20(_token).transfer(_receiver, _amount), "ERC20Handler: token transfer failed");
    }
}

// File: contracts/Bridge.sol



pragma solidity ^0.8.0;






contract Bridge is ERC20Handler, HashIndexer, Ownable {
    ISignersRepository public signersRep;

    event DepositERC20(
        string receiver,
        address token,
        uint256 amount,
        string network
    );

    constructor(address _signersRep){
        signersRep = ISignersRepository(_signersRep);
    }

    function checkSignersCopies(address[]memory _signers) private pure returns (bool){
        if (_signers.length == 1) {
            return false;
        }

        for (uint8 i = 0; i < _signers.length - 1; i++) {
            for (uint8 q = i + 1; q < _signers.length; q++) {
                if (_signers[i] == _signers[q]) {
                    return true;
                }
            }
        }

        return false;
    }

    function withdrawERC20(address _token, address _receiver, uint256 _amount) onlyOwner external {
        _sendERC20(_token, _receiver, _amount);
    }

    function withdrawERC20(
        address _token,
        string memory _txHash,
        uint256 _amount,
        bytes32[] memory _r,
        bytes32[] memory _s,
        uint8[] memory _v
    ) onlyInexistentHash(_txHash) external {
        address[] memory _signers = _deriveERC20Signers(_token, _txHash, _amount, _r, _s, _v);

        require(
            !checkSignersCopies(_signers),
            "Bridge: signatures contain copies"
        );
        require(
            signersRep.containsSigners(_signers),
            "Bridge: bad signatures"
        );

        _addHash(_txHash);
        _sendERC20(_token, msg.sender, _amount);
    }

    function depositERC20(address _token, string memory _receiver, uint256 _amount, string memory _network) external {
        require(IERC20(_token).transferFrom(msg.sender, address(this), _amount), "token transfer failed");

        emit DepositERC20(_receiver, _token, _amount, _network);
    }

    function withdrawNative(address _receiver, uint256 _amount) onlyOwner external {
        payable(_receiver).transfer(_amount);
    }

    function setSignersRep(address _signersRep) external onlyOwner {
        signersRep = ISignersRepository(_signersRep);
    }
}