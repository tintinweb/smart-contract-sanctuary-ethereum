import "./VerifySignature.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

pragma solidity ^0.8.0;

interface Minimalmint {
    function mintafterverification(
        uint256 value1,
        uint256 value2,
        uint256 colorpointer,
        uint256 tokenid,
        string memory rtimetamp
    ) external;
}

contract Minting is VerifySignature, Ownable {
    Minimalmint minter;
    address internal dataprovider;
    uint256 public nonce;
    uint256 public constant mint_price = 150000000000000000 wei;

    address public currentcurator;
    address public terra0multisig;
    mapping(address => curator) public curators;

    uint256 public maxnonce = 2001;
    uint256[2] public temprange = [19000, 23000];
    uint256[2] public moistrange = [70000, 80000];

    uint256 public timelimit = 2200;
    uint256 public artistmintcounter = 15;

    struct curator {
        uint256 percentage;
        uint256 colorandlocationpointer;
        bool curatorwhitelist;
        uint256 curatorshares;
    }

    constructor(
        address _dataprovider,
        address _terra0multisig,
        address _erc721
    ) {
        dataprovider = _dataprovider;
        terra0multisig = _terra0multisig;
        nonce = 0;
        maxnonce = 1601;
        timelimit = 2200;
        minter = Minimalmint(_erc721);

    }

    function checkrange(
        uint256 value,
        uint256 downrange,
        uint256 upperrange
    ) public pure returns (bool pass) {
        bool down = value >= downrange;
        bool up = value <= upperrange;
        return (bool(down && up));
    }

    function artistmint(
        uint256 value1,
        uint256 value2,
        uint256 _nonce,
        string memory htimestamp,
        uint256 colorandlocationpointer
    ) external onlyOwner {
        require(_nonce < maxnonce, "Max number of tokens minted");
        require(currentcurator != address(0), "No curator set");

        require(
            checkrange(value1, moistrange[0], moistrange[1]) == true,
            "Moisture range out of bounds"
        );
        require(
            checkrange(value2, temprange[0], temprange[1]) == true,
            "Temperature range out of bounds"
        );
        require(artistmintcounter > 0);
        artistmintcounter -= 1;
        minter.mintafterverification(
            value1,
            value2,
            colorandlocationpointer,
            _nonce,
            htimestamp
        );
        nonce = _nonce;
    }

    function mintwithSignedData(
        address signer,
        uint256 value1,
        uint256 value2,
        uint256 _nonce,
        uint256 timestamp,
        string memory htimestamp,
        bytes memory signature
    ) external payable {
        require(
            verify(
                signer,
                value1,
                value2,
                _nonce,
                timestamp,
                htimestamp,
                signature
            ) == true,
            "Wrong signature"
        );
        require(signer == dataprovider, "Signer is not dataprovider");
        require(_nonce > nonce, "Datapacket already minted");
        uint256 latest_date = block.timestamp - timelimit;
        require(timestamp > latest_date, "Datapacket too old");
        require(msg.value >= mint_price, "Insufficient payment");
        require(currentcurator != address(0), "No curator set");
        require(_nonce < maxnonce, "Max number tokens minted");
        require(
            checkrange(value1, moistrange[0], moistrange[1]) == true,
            "Moisture range out of bounds"
        );
        require(
            checkrange(value2, temprange[0], temprange[1]) == true,
            "Temperature range out of bounds"
        );
        nonce = _nonce;
        minter.mintafterverification(
            value1,
            value2,
            curators[currentcurator].colorandlocationpointer,
            _nonce,
            htimestamp
        );
        curators[currentcurator].curatorshares =
            curators[currentcurator].curatorshares +
            (mint_price / curators[currentcurator].percentage);
        uint256 terra0value = mint_price -
            (mint_price / curators[currentcurator].percentage);
        (bool sent, ) = payable(terra0multisig).call{value: terra0value}("");
        require(sent, "Transfer failed.");
    }

    function setcurator(
        address _curator,
        uint256 percentage,
        uint256 colorandlocationpointer
    ) external onlyOwner {
        currentcurator = _curator;
        curators[currentcurator].curatorwhitelist = false;
        curators[currentcurator]
            .colorandlocationpointer = colorandlocationpointer;
        curators[currentcurator].percentage = percentage;
    }

    function whitelistwithdrawcurator(address _curator) external onlyOwner {
        curators[_curator].curatorwhitelist = true;
    }

    function withdraw() external {
        require(
            curators[msg.sender].curatorwhitelist == true,
            "Exhibition still running"
        );
        uint256 share = curators[msg.sender].curatorshares;
        curators[msg.sender].curatorshares = 0;
        (bool sent, ) = msg.sender.call{value: share}("");
        require(sent, "Transfer failed.");
    }

    function changetimelimit(uint256 newtimelimit) external onlyOwner {
        timelimit = newtimelimit;
    }

    function changevaluerange(
        uint256 temprange0,
        uint256 temprange1,
        uint256 moistrange0,
        uint256 moistrange1
    ) public onlyOwner {
        temprange[0] = temprange0;
        temprange[1] = temprange1;
        moistrange[0] = moistrange0;
        moistrange[1] = moistrange1;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VerifySignature {

    function getMessageHash(
        uint256 value1,
        uint256 value2,
        uint256 nonce,
        uint256 timestamp,
        string memory htimestamp
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encode(value1, value2, nonce, timestamp, htimestamp)
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

    function verify(
        address _signer,
        uint256 _value1,
        uint256 _value2,
        uint256 _nonce,
        uint256 _timestamp,
        string memory htimestamp,
        bytes memory signature
    ) public pure returns (bool) {
        bytes32 messageHash = getMessageHash(
            _value1,
            _value2,
            _nonce,
            _timestamp,
            htimestamp
        );
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recoverSigner(ethSignedMessageHash, signature) == _signer;
    }

    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) public pure returns (address) {
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
            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }
}

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