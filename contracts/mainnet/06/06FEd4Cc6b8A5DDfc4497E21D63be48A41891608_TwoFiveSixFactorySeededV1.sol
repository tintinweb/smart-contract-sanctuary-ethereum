// SPDX-License-Identifier: MIT

/* 

██████╗ ███████╗ ██████╗ 
╚════██╗██╔════╝██╔════╝ 
 █████╔╝███████╗███████╗ 
██╔═══╝ ╚════██║██╔═══██╗
███████╗███████║╚██████╔╝
╚══════╝╚══════╝ ╚═════╝ 

Using this contract? 
A shout out to @Mint256Art is appreciated!
 */

pragma solidity ^0.8.19;

import "./helpers/SSTORE2.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TwoFiveSixFactorySeededV1 is Ownable {
    address payable private _twoFiveSixAddress;

    address public masterProject;

    address[] public projects;

    /* Percentage multiplied by 100 */
    uint256 public twoFiveSixSharePrimary;

    uint256 public biddingDelay;
    uint256 public allowListDelay;

    event Deployed(address a);

    /**
     * @notice Launches a new TwoFiveSixProjectSeeded with the provided project, traits, libraries, and seed.
     * @dev The `masterProjectSeeded` is used as the contract implementation.
     * @param _project A struct containing details about the project being launched.
     * @param _traits An array of structs containing details about the traits associated with the project.
     * @param _libraries An array of structs containing details about the libraries used by the project.
     */
    function launchProject(
        ITwoFiveSixProject.Project memory _project,
        ITwoFiveSixProject.Trait[] calldata _traits,
        ITwoFiveSixProject.LibraryScript[] calldata _libraries
    ) public {
        require(
            _project.biddingStartTimeStamp > block.timestamp + biddingDelay,
            "Before minimum bidding delay"
        );
        require(
            _project.allowListStartTimeStamp > block.timestamp + allowListDelay,
            "Before allow list delay"
        );
        require(
            _project.twoFiveSix == _twoFiveSixAddress,
            "Incorrect 256ART address"
        );
        require(
            _project.twoFiveSixShare == uint24(twoFiveSixSharePrimary),
            "Incorrect 256ART share"
        );
        require(
            twoFiveSixSharePrimary + _project.thirdPartyShare <= 10000,
            "Third party share too high"
        );

        address a = clone(masterProject);

        address traits;

        address libraryScripts;

        if (_traits.length > 0) {
            traits = SSTORE2.write(abi.encode(_traits));
        }

        if (_libraries.length > 0) {
            libraryScripts = SSTORE2.write(abi.encode(_libraries));
        }

        ITwoFiveSixProject p = ITwoFiveSixProject(a);

        p.initProject(_project, traits, libraryScripts);
        projects.push(a);
        emit Deployed(a);
    }

    /**
     * @notice Clones a contract using the provided implementation address
     * @param implementation The address of the contract implementation
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(
                ptr,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(
                add(ptr, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Set the master project address
     * @notice Only the contract owner can call this function
     * @param _masterProject Address of the new master project contract
     */
    function setMasterProject(address _masterProject) public onlyOwner {
        masterProject = _masterProject;
    }

    /**
     * @dev Set the 256 address
     * @notice Only the contract owner can call this function
     * @param newAddress The new 256 contract address
     */
    function setTwoFiveSixAddress(address payable newAddress) public onlyOwner {
        _twoFiveSixAddress = newAddress;
    }

    /**
     * @dev Set the primary 256 share
     * @notice Only the contract owner can call this function
     * @param newShare The new primary 256 share
     */
    function setTwoFiveSixSharePrimary(uint256 newShare) public onlyOwner {
        twoFiveSixSharePrimary = newShare;
    }

    /**
     * @dev Set the bidding delay
     * @notice Only the contract owner can call this function
     * @param delay The new bidding delay
     */
    function setBiddingDelay(uint256 delay) public onlyOwner {
        biddingDelay = delay;
    }

    /**
     * @dev Set the allow list delay
     * @notice Only the contract owner can call this function
     * @param delay The new allow list delay
     */
    function setAllowListDelay(uint256 delay) public onlyOwner {
        allowListDelay = delay;
    }
}

interface ITwoFiveSixProject {
    struct Project {
        string name; //unknown
        string imageBase; //unkown
        address[] artScripts; //unknown
        bytes32 merkleRoot; //32
        address artInfo; //20
        uint56 biddingStartTimeStamp; //8
        uint32 maxSupply; //4
        address payable artistAddress; //20
        uint56 allowListStartTimeStamp; //8
        uint32 totalAllowListMints; //4
        address payable twoFiveSix; //20
        uint24 artistAuctionWithdrawalsClaimed; //3
        uint24 artistAllowListWithdrawalsClaimed; //3
        uint24 twoFiveSixShare; //3
        uint24 royalty; //3
        address traits; //20
        uint96 reservePrice; //12
        address payable royaltyAddress; //20
        uint96 lastSalePrice; //12
        address libraryScripts; //20
        uint56 endingTimeStamp; //8
        uint24 thirdPartyShare; //3
        bool fixedPrice; //1
        address payable thirdPartyAddress; //20
    }
    struct Trait {
        string name;
        string[] values;
        string[] descriptions;
        uint256[] weights;
    }

    struct TotalAndCount {
        uint128 total;
        uint128 count;
    }
    struct LibraryScript {
        address fileStoreFrontEnd;
        address fileStore;
        string fileName;
    }

    function initProject(
        Project calldata _p,
        address _traits,
        address _libraryScripts
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Bytecode {
    error InvalidCodeAtRange(uint256 _size, uint256 _start, uint256 _end);

    /**
    @notice Generate a creation code that results on a contract with `_code` as bytecode
    @param _code The returning value of the resulting `creationCode`
    @return creationCode (constructor) for new contract
  */
    function creationCodeFor(bytes memory _code)
        internal
        pure
        returns (bytes memory)
    {
        /*
      0x00    0x63         0x63XXXXXX  PUSH4 _code.length  size
      0x01    0x80         0x80        DUP1                size size
      0x02    0x60         0x600e      PUSH1 14            14 size size
      0x03    0x60         0x6000      PUSH1 00            0 14 size size
      0x04    0x39         0x39        CODECOPY            size
      0x05    0x60         0x6000      PUSH1 00            0 size
      0x06    0xf3         0xf3        RETURN
      <CODE>
    */

        return
            abi.encodePacked(
                hex"63",
                uint32(_code.length),
                hex"80_60_0E_60_00_39_60_00_F3",
                _code
            );
    }

    /**
    @notice Returns the size of the code on a given address
    @param _addr Address that may or may not contain code
    @return size of the code on the given `_addr`
  */
    function codeSize(address _addr) internal view returns (uint256 size) {
        assembly {
            size := extcodesize(_addr)
        }
    }

    /**
    @notice Returns the code of a given address
    @dev It will fail if `_end < _start`
    @param _addr Address that may or may not contain code
    @param _start number of bytes of code to skip on read
    @param _end index before which to end extraction
    @return oCode read from `_addr` deployed bytecode

    Forked from: https://gist.github.com/KardanovIR/fe98661df9338c842b4a30306d507fbd
  */
    function codeAt(
        address _addr,
        uint256 _start,
        uint256 _end
    ) internal view returns (bytes memory oCode) {
        uint256 csize = codeSize(_addr);
        if (csize == 0) return bytes("");

        if (_start > csize) return bytes("");
        if (_end < _start) revert InvalidCodeAtRange(csize, _start, _end);

        unchecked {
            uint256 reqSize = _end - _start;
            uint256 maxSize = csize - _start;

            uint256 size = maxSize < reqSize ? maxSize : reqSize;

            assembly {
                // allocate output byte array - this could also be done without assembly
                // by using o_code = new bytes(size)
                oCode := mload(0x40)
                // new "memory end" including padding
                mstore(
                    0x40,
                    add(oCode, and(add(add(size, 0x20), 0x1f), not(0x1f)))
                )
                // store length in memory
                mstore(oCode, size)
                // actually retrieve the code, this needs assembly
                extcodecopy(_addr, add(oCode, 0x20), _start, size)
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./Bytecode.sol";

library SSTORE2 {
    error WriteError();

    /**
    @notice Stores `_data` and returns `pointer` as key for later retrieval
    @dev The pointer is a contract address with `_data` as code
    @param _data to be written
    @return pointer Pointer to the written `_data`
  */
    function write(bytes memory _data) internal returns (address pointer) {
        // Append 00 to _data so contract can't be called
        // Build init code
        bytes memory code = Bytecode.creationCodeFor(
            abi.encodePacked(hex"00", _data)
        );

        // Deploy contract using create
        assembly {
            pointer := create(0, add(code, 32), mload(code))
        }

        // Address MUST be non-zero
        if (pointer == address(0)) revert WriteError();
    }

    /**
    @notice Reads the contents of the `_pointer` code as data, skips the first byte 
    @dev The function is intended for reading pointers generated by `write`
    @param _pointer to be read
    @return data read from `_pointer` contract
  */
    function read(address _pointer) internal view returns (bytes memory) {
        return Bytecode.codeAt(_pointer, 1, type(uint256).max);
    }

    /**
    @notice Reads the contents of the `_pointer` code as data, skips the first byte 
    @dev The function is intended for reading pointers generated by `write`
    @param _pointer to be read
    @param _start number of bytes to skip
    @return data read from `_pointer` contract
  */
    function read(address _pointer, uint256 _start)
        internal
        view
        returns (bytes memory)
    {
        return Bytecode.codeAt(_pointer, _start + 1, type(uint256).max);
    }

    /**
    @notice Reads the contents of the `_pointer` code as data, skips the first byte 
    @dev The function is intended for reading pointers generated by `write`
    @param _pointer to be read
    @param _start number of bytes to skip
    @param _end index before which to end extraction
    @return data read from `_pointer` contract
  */
    function read(
        address _pointer,
        uint256 _start,
        uint256 _end
    ) internal view returns (bytes memory) {
        return Bytecode.codeAt(_pointer, _start + 1, _end + 1);
    }
}