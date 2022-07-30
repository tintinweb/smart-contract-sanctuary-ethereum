// SPDX-License-Identifier: MIT

/**                                                                
 *******************************************************************************
 * Sharkz Soul ID Data
 *******************************************************************************
 * Creator: Sharkz
 * Author: Jason Hoi
 * Date: 2022-07-30
 *
 */

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "./ISoulData.sol";
import "./vote/IVoteScore.sol";
import "../sharkz/Adminable.sol";

interface IBalanceOf {
  function balanceOf(address owner) external view returns (uint256 balance);
}

interface IBalanceOfSoul {
  function balanceOfSoul(address soulContract, uint256 soulTokenId) external view returns (uint256 balance);
}

interface IName {
  function name() external view returns (string memory);
}

contract SoulData is ISoulData, Adminable {
    struct ContractData {
        address rawContract;
        uint16 size;
    }

    struct ContractDataPages {
        uint256 maxPageNumber;
        bool exists;
        mapping (uint256 => ContractData) pages;
    }

    // Mapping from string key to on-chain contract data storage 
    mapping (string => ContractDataPages) internal _contractDataPages;

    constructor() {}

    /**
     * @dev See {ISharkzSoulIDData-tokenImage}.
     */
    function tokenImage(uint256 _tokenId, uint256 _creationTime) 
        external 
        view 
        override 
        returns (string memory) 
    {
        string memory svgHead = string(getData('svgHead'));
        return string(
            abi.encodePacked(
                svgHead,
                _svgText(_creationTime, _tokenId),
                "</svg>"
            )
        );
    }

    // render dynamic svg <text> element with token creation timestamp and tokenId
    function _svgText(uint256 _time, uint256 _tokenId) 
        internal 
        pure 
        returns (string memory) 
    {
        // <text text-anchor='middle' x='191.34' y='270' fill='#8ecad8' font-family='custom' font-size='12'>{time}#{tokenId}</text>
        return string(
            abi.encodePacked(
                "<text text-anchor='middle' x='191.34' y='270' fill='#8ecad8' font-family='custom' font-size='12'>",
                toString(_time),
                "#",
                toString(_tokenId),
                "</text>"
            )
        );
    }

    /**
     * @dev See {ISharkzSoulIDData-saveData}.
     */
    function saveData(
        string memory _key, 
        uint256 _pageNumber, 
        bytes memory _b
    )
        external 
        override 
        onlyAdmin 
    {
        require(_b.length <= 24576, "Exceeded 24,576 bytes max contract space");
        /**
         * 
         * `init` variable is the header of contract data
         * 61_00_00 -- PUSH2 (contract code size)
         * 60_00 -- PUSH1 (code position)
         * 60_00 -- PUSH1 (mem position)
         * 39 CODECOPY
         * 61_00_00 PUSH2 (contract code size)
         * 60_00 PUSH1 (mem position)
         * f3 RETURN
         *
        **/
        bytes memory init = hex"610000_600e_6000_39_610000_6000_f3";
        bytes1 size1 = bytes1(uint8(_b.length));
        bytes1 size2 = bytes1(uint8(_b.length >> 8));
        // 2 bytes = 2 x uint8 = 65,536 max contract code size
        init[1] = size2;
        init[2] = size1;
        init[9] = size2;
        init[10] = size1;
        
        // contract code content
        bytes memory code = abi.encodePacked(init, _b);

        // create the contract
        address dataContract;
        assembly {
            dataContract := create(0, add(code, 32), mload(code))
            if eq(dataContract, 0) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }

        // record the created contract data page
        _saveDataRecord(
            _key,
            _pageNumber,
            dataContract,
            _b.length
        );
    }

    // store the generated contract data store address
    function _saveDataRecord(
        string memory _key,
        uint256 _pageNumber,
        address _dataContract,
        uint256 _size
    )
        internal
    {
        // Pull the current data for the contractData
        ContractDataPages storage _cdPages = _contractDataPages[_key];

        // Store the maximum page
        if (_cdPages.maxPageNumber < _pageNumber) {
            _cdPages.maxPageNumber = _pageNumber;
        }

        // Keep track of the existance of this key
        _cdPages.exists = true;

        // Add the page to the location needed
        _cdPages.pages[_pageNumber] = ContractData(
            _dataContract,
            uint16(_size)
        );
    }

    /**
     * @dev See {ISharkzSoulIDData-getPageData}.
     */
    function getPageData(
        string memory _key,
        uint256 _pageNumber
    )
        external 
        view 
        override 
        returns (bytes memory)
    {
        ContractDataPages storage _cdPages = _contractDataPages[_key];
        
        require(_pageNumber <= _cdPages.maxPageNumber, "Page number not in range");
        bytes memory _totalData = new bytes(_cdPages.pages[_pageNumber].size);

        // For each page, pull and compile
        uint256 currentPointer = 32;

        ContractData storage dataPage = _cdPages.pages[_pageNumber];
        address dataContract = dataPage.rawContract;
        uint256 size = uint256(dataPage.size);
        uint256 offset = 0;

        // Copy directly to total data
        assembly {
            extcodecopy(dataContract, add(_totalData, currentPointer), offset, size)
        }
        return _totalData;
    }

    /**
     * @dev See {ISharkzSoulIDData-getData}.
     */
    function getData(
        string memory _key
    )
        public 
        virtual 
        view 
        override 
        returns (bytes memory)
    {
        ContractDataPages storage _cdPages = _contractDataPages[_key];

        // Determine the total size
        uint256 totalSize;
        for (uint256 idx; idx <= _cdPages.maxPageNumber; idx++) {
            totalSize += _cdPages.pages[idx].size;
        }

        // Create a region large enough for all of the data
        bytes memory _totalData = new bytes(totalSize);

        // For each page, pull and compile
        uint256 currentPointer = 32;
        for (uint256 idx; idx <= _cdPages.maxPageNumber; idx++) {
            ContractData storage dataPage = _cdPages.pages[idx];
            address dataContract = dataPage.rawContract;
            uint256 size = uint256(dataPage.size);
            uint256 offset = 0;

            // Copy directly to total data
            assembly {
                extcodecopy(dataContract, add(_totalData, currentPointer), offset, size)
            }

            // Update the current pointer
            currentPointer += size;
        }

        return _totalData;
    }

    /**
     * @dev See {ISharkzSoulIDData-getTokenCollectionName}.
     */
    function getTokenCollectionName(address _contract) public view returns (string memory) {
        try IName(_contract).name() returns (string memory name) {
            return name;
        } catch (bytes memory) {
            // when reverted, just returns...
            return "";
        }
    }

    /**
     * @dev See {ISharkzSoulIDData-getSoulBadgeVoteScore}.
     */
    function getSoulBadgeVoteScore(address _badgeContract) external virtual pure returns (uint256) {
        try IVoteScore(_badgeContract).voteScore() returns (uint256 score) {
            return score;
        } catch (bytes memory) {
            // when reverted, just return false
            return 0;
        }
    }

    /**
     * @dev See {ISharkzSoulIDData-getBadgeTrait}.
     */
     function getBadgeTrait(address _badgeContract, uint256 _traitIndex, address _soulContract, uint256 _soulTokenId, address _soulTokenOwner) external view returns (string memory) {
        string memory output;
        string memory traitName;
        string memory traitValue;

        traitValue = getTokenCollectionName(_badgeContract);

        // ERC165 interface ID for ERC721 is 0x80ac58cd
        if (isImplementing(_badgeContract, 0x80ac58cd)) {
            // target contract is ERC721
            if (getERC721Balance(_badgeContract, _soulTokenOwner) > 0) {
                if (bytes(traitValue).length != 0) {
                    traitName = string(abi.encodePacked("ERC721 NFT ", toAlphabetCode(_traitIndex)));
                    output = string(abi.encodePacked(output, '{"trait_type":"',traitName,'","value":"',traitValue, '"},'));
                }
            }
        } else {
            // target contract is Soul Badge contracts
            if (getSoulBadgeBalanceForSoul(_soulContract, _soulTokenId, _badgeContract) > 0) {
                if (bytes(traitValue).length != 0) {
                    traitName = string(abi.encodePacked("Soul Badge ", toAlphabetCode(_traitIndex)));
                    output = string(abi.encodePacked(output, '{"trait_type":"',traitName,'","value":"',traitValue, '"},'));
                }
            }    
        }
        return output;
    }

    /**
     * @dev See {ISharkzSoulIDData-getTokenBalance}.
     */
    function getSoulBadgeBalanceForSoul(address _soulContract, uint256 _soulTokenId, address _badgeContract) public view returns (uint256) {
        if (_soulContract == address(0) || _badgeContract == address(0)) return 0;
        
        try IBalanceOfSoul(_badgeContract).balanceOfSoul(_soulContract, _soulTokenId) returns (uint256 rtbal) {
            return rtbal;
        } catch (bytes memory) {
            // when reverted, just returns...
            return 0;
        }
    }

    /**
     * @dev See {ISharkzSoulIDData-getERC721Balance}.
     */
    function getERC721Balance(address _contract, address _ownerAddress) public view returns (uint256) {
        if (_contract == address(0) || _ownerAddress == address(0)) return 0;

        try IBalanceOf(_contract).balanceOf(_ownerAddress) returns (uint256 balance) {
            return balance;
        } catch (bytes memory) {
            // when reverted, just returns...
            return 0;
        }
    }

    /**
     * @dev See {ISharkzSoulIDData-isImplementing}.
     */
    function isImplementing(address _contract, bytes4 _interfaceCode) public view returns (bool) {
        try IERC165(_contract).supportsInterface(_interfaceCode) returns (bool result) {
            return result;
        } catch (bytes memory) {
            // when reverted, just returns...
            return false;
        }
    }

    /**
     * @dev See {ISharkzSoulIDData-toAlphabetCode}.
     */
    function toAlphabetCode(uint256 value) 
        public 
        pure 
        override 
    returns (string memory) {
        // base 26 alphabet codes starts from A
        if (value == 0) {
            return "A";
        }
        // calculate string length
        uint256 temp = value;
        uint256 letters = 0;
        while (temp != 0) {
            letters += 1;
            temp /= 26;
        }
        uint256 max = letters - 1;
        // construct output string bytes
        bytes memory buffer = new bytes(letters);
        while (value != 0) {
            letters -= 1;
            if (letters < max) {
                buffer[letters] = bytes1(uint8(64 + uint256(value % 26)));
            } else {
                buffer[letters] = bytes1(uint8(65 + uint256(value % 26)));
            }
            value /= 26;
        }
        return string(buffer);
    }

    /**
     * Converts `uint256` to ASCII `string`
     */
    function toString(uint256 value) 
        public 
        pure 
        returns (string memory ptr) 
    {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit),
            // but we allocate 128 bytes to keep the free memory pointer 32-byte word aliged.
            // We will need 1 32-byte word to store the length,
            // and 3 32-byte words to store a maximum of 78 digits. Total: 32 + 3 * 32 = 128.
            ptr := add(mload(0x40), 128)
            // Update the free memory pointer to allocate.
            mstore(0x40, ptr)

            // Cache the end of the memory to calculate the length later.
            let end := ptr

            // We write the string from the rightmost digit to the leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // Costs a bit more than early returning for the zero case,
            // but cheaper in terms of deployment and overall runtime costs.
            for {
                // Initialize and perform the first pass without check.
                let temp := value
                // Move the pointer 1 byte leftwards to point to an empty character slot.
                ptr := sub(ptr, 1)
                // Write the character to the pointer. 48 is the ASCII index of '0'.
                mstore8(ptr, add(48, mod(temp, 10)))
                temp := div(temp, 10)
            } temp {
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
            } {
                // Body of the for loop.
                ptr := sub(ptr, 1)
                mstore8(ptr, add(48, mod(temp, 10)))
            }

            let length := sub(end, ptr)
            // Move the pointer 32 bytes leftwards to make room for the length.
            ptr := sub(ptr, 32)
            // Store the length.
            mstore(ptr, length)
        }
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

/**
 *******************************************************************************
 * ISharkzSoulIDData interface
 *******************************************************************************
 * Creator: Sharkz
 * Author: Jason Hoi
 * Date: 2022-07-30
 *
 */

pragma solidity ^0.8.7;

/**
 * @dev Interface of Sharkz external contract data storage
 */
interface ISoulData {
    /**
     * @dev Save/Reset a page of data with a key, max size is 24576 bytes (24KB), 
     * please prepare your data in binary chunks.
     */
    function saveData(string memory key, uint256 pageNumber, bytes memory data) external;

    /**
     * @dev Get all data from all data pages for a key
     */
    function getData(string memory key) external view returns (bytes memory);

    /**
     * @dev Get one page of data chunk
     */
    function getPageData(string memory key, uint256 pageNumber) external view returns (bytes memory);
    
    /**
     * @dev Get svg token image
     */
    function tokenImage(uint256 tokenId, uint256 creationTime) external view returns (string memory);

    /**
     * @dev Try to get external Token collection name
     */
    function getTokenCollectionName(address _contract) external view returns (string memory);

    /**
     * @dev Returns Soul Balance for a Soul Badge contract
     */
    function getSoulBadgeBalanceForSoul(address _soulContract, uint256 _soulTokenId, address _badgeContract) external view returns (uint256);

    /**
     * @dev Returns Soul Badge uint vote score
     */
    function getSoulBadgeVoteScore(address _badgeContract) external pure returns (uint256);

    /**
     * @dev Returns the token metadata trait string for a badge contract (support ERC721 and ERC5114 Soul Badge)
     */
    function getBadgeTrait(address _badgeContract, uint256 _traitIndex, address _soulContract, uint256 _soulTokenId, address _soulTokenOwner) external view returns (string memory);

    /**
     * @dev Returns whether an address is token owner
     */
    function getERC721Balance(address _contract, address _ownerAddress) external view returns (uint256);

    /**
     * @dev Returns whether target contract reported it implementing an interface (based on IERC165)
     */
    function isImplementing(address _contract, bytes4 _interfaceCode) external view returns (bool);

    /** 
     * @dev Converts a `uint256` to ASCII base26 alphabet sequence code
     * For example, 0:A, 1:B 2:C ... 25:Z, 26:AA, 27:AB...
     */
    function toAlphabetCode(uint256 value) external pure returns (string memory);

    /**
     * @dev Converts `uint256` to ASCII `string`
     */
    function toString(uint256 value) external pure returns (string memory ptr);
}

// SPDX-License-Identifier: MIT

/**
 *******************************************************************************
 * IVoteScore interface
 *******************************************************************************
 * Creator: Sharkz
 * Author: Jason Hoi
 * Date: 2022-07-21
 *
 */

pragma solidity ^0.8.7;

/**
 * @dev Interface of voting score, it allows external contract to use the score
 * to calculate voting power.
 */
interface IVoteScore {
    /**
     * @dev Get vote score for each one token (each token get same unit score)
     */
    function voteScore() external pure returns (uint256);

    /**
     * @dev Get vote score for individual `tokenId`
     * This function is needed only when score varies between token ids.
     * In order to accumulate score, try to avoid any revert() if user submitted 
     * non-existent token id or owner address.
     *
     */
    function voteScoreByToken(uint256 tokenId) external view returns (uint256);

    /**
     * @dev Get vote score of an address
     * In order to accumulate score, try to avoid any revert() if user submitted 
     * non-existent token id or owner address.
     *
     */
    function voteScoreByAddress(address addr) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

/**
 *******************************************************************************
 * Adminable access control
 *******************************************************************************
 * Creator: Sharkz
 * Author: Jason Hoi
 * Date: 2022-07-27
 *
 */
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @dev Contract module which provides basic multiple admins access control 
 * mechanism, admins are granted exclusive access to specific functions with the 
 * provided modifier.
 *
 * By default, the contract owner is the first admin.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyAdmin`, which can be applied to your functions to restrict access for  
 * admins only.
 * 
 */
contract Adminable is Context {
    event AdminCreated(address indexed addr);
    event AdminRemoved(address indexed addr);
    event AdminTransfer(address indexed from, address indexed to);

    // Array of admin addresses
    address[] private _admins;

    // add the first admin with contract creator
    constructor() {
        _createAdmin(_msgSender());
    }

    modifier onlyAdmin() {
        require(_msgSender() != address(0), "Adminable: caller is the zero address");

        bool found = false;
        for (uint256 i = 0; i < _admins.length; i++) {
            if (_msgSender() == _admins[i]) {
                found = true;
            }
        }
        require(found, "Adminable: caller is not admin");
        _;
    }

    function isAdmin(address addr) public view virtual onlyAdmin returns (bool) {
        for (uint256 i = 0; i < _admins.length; i++) {
          if (addr == _admins[i])
          {
            return true;
          }
        }
        return false;
    }

    function countAdmin() external view virtual returns (uint256) {
        return _admins.length;
    }

    function getAdmin(uint256 _index) external view virtual onlyAdmin returns (address) {
        return _admins[_index];
    }

    function setAdmin(address to, bool approved) public virtual onlyAdmin {
        bool existingAdmin = isAdmin(to);

        // approve = true, adding
        // approve = false, removing
        if (approved) {
            require(!existingAdmin, "Adminable: add admin for existing admin");
            _createAdmin(to);

        } else {
            // for safety, prevent removing initial admin
            require(to != _admins[0], "Adminable: can not remove initial admin with setAdmin");

            // remove existing admin
            require(existingAdmin, "Adminable: remove non-existent admin");
            uint256 total = _admins.length;

            // replace current array element with last element, and pop() remove last element
            if (to != _admins[total - 1]) {
                _admins[_adminIndex(to)] = _admins[total - 1];
                _admins.pop();
            } else {
                _admins.pop();
            }

            emit AdminRemoved(to);
        }
    }

    function _adminIndex(address addr) internal view virtual returns (uint256) {
        for (uint256 i = 0; i < _admins.length; i++) {
            if (addr == _admins[i] && addr != address(0)) {
                return i;
            }
        }
        revert("Adminable: admin index not found");
    }

    function _createAdmin(address addr) internal virtual {
        _admins.push(addr);
        emit AdminCreated(addr);
    }

    /**
     * @dev Transfers message sender admin account to a new address
     */
    function transferAdmin(address to) public virtual onlyAdmin {
        require(to != address(0), "Adminable: address is the zero address");
        
        _admins[_adminIndex(_msgSender())] = to;
        emit AdminTransfer(_msgSender(), to);
    }

    /**
     * @dev Leaves the contract without admin.
     *
     * NOTE: Renouncing the last admin will leave the contract without any admins,
     * thereby removing any functionality that is only available to admins.
     */
    function renounceLastAdmin() public virtual onlyAdmin {
        require(_admins.length == 1, "Adminable: can not renounce admin when there are more than one admins");

        delete _admins;
        emit AdminRemoved(_msgSender());
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