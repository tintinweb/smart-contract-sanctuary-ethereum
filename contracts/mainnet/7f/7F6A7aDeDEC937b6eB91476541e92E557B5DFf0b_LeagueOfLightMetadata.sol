// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

abstract contract Context {
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
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

abstract contract Ownable is Context {
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
    address private _owner;
    address private admin;

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
        require(owner() == _msgSender() || admin == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    //Additional function added by ktrby
    function registerAdmin(address _admin) public onlyOwner {
        admin = _admin;
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

contract LeagueOfLightMetadata is Ownable {
    struct metadata {
        string title;
        string category;
        string description;
        string imageUrl;
        string animationUrl;
        string material;
        string monarch;
    }
    address private lolContractAddress;

    // SETUP FUNCTIONS //

    function setLolContractAddress(address _addr) public onlyOwner {
        lolContractAddress = _addr;
    }

    // CREATE METADATA //

    function getMonarchMetadata(uint id1, uint id2) internal pure returns (metadata memory) {
        string memory title;
        string memory description = "\'light your own fire\'";
        string memory imageUrl = "https://gateway.pinata.cloud/ipfs/QmXW6eizhk3kkcQEsnpCN65jbGzgt53npARptnTe1ptUzP/monarch.jpg";
        string memory animationUrl = "https://gateway.pinata.cloud/ipfs/QmXW6eizhk3kkcQEsnpCN65jbGzgt53npARptnTe1ptUzP/monarch.mp4";

        uint r1 = id1 % 6;
        uint r2 = id2 % 6;
        string memory c1;
        string memory c2;
        if (r1 == 0 || r1 == 1) {c1 = "Light";}
        else if (r1 == 2) {c1 = "Shadow";}
        else if (r1 == 3) {c1 = "Hope";}
        else if (r1 == 4) {c1 = "Dreams";}
        if (r2 == 0 || r2 == 1) {c2 = "Light";}
        else if (r2 == 2) {c2 = "Shadow";}
        else if (r2 == 3) {c2 = "Hope";}
        else if (r2 == 4) {c2 = "Dreams";}

        if (keccak256(abi.encodePacked((c1))) == keccak256(abi.encodePacked((c2))) && r1 != 5) {
            title = string(abi.encodePacked("Monarch of ", c1));
        } else {
            title = string(abi.encodePacked("Monarch of ", c1, " & ", c2));
        }

        if (r1 == 5 || r2 == 5) {
            description = "\'silence speaks louder than words\'";
            imageUrl = "https://gateway.pinata.cloud/ipfs/QmXW6eizhk3kkcQEsnpCN65jbGzgt53npARptnTe1ptUzP/theunheard.jpg";
            animationUrl = "https://gateway.pinata.cloud/ipfs/QmXW6eizhk3kkcQEsnpCN65jbGzgt53npARptnTe1ptUzP/theunheard.mp4";
            
            if (r1 == 5) {
                title = string(abi.encodePacked("Unheard Monarch of ", c2));
            } else if (r2 == 5) {
                title = string(abi.encodePacked("Unheard Monarch of ", c1));
            }
            if (r1 == r2) {
                title = "Unheard Monarch";
            }
        }

        return metadata(title, "", description, imageUrl, animationUrl, "Ti", "True");
    }

    function getMetadata(uint tokenId, uint s) internal pure returns (metadata memory) {
        string memory title;
        string memory category;
        string memory description;
        string memory imageUrl;
        string memory animationUrl;
        string memory material;

        uint256 r = tokenId % 6;

        imageUrl = string(abi.encodePacked(
            "https://gateway.pinata.cloud/ipfs/QmPWX4N5tnWHp9NNmgfaFUfU83JsmtMoyJtmpN9vnSDoS5/",
            toString(r),
            "-",
            toString(s),
            ".jpg"
        ));
        animationUrl = string(abi.encodePacked(
            "https://gateway.pinata.cloud/ipfs/QmWoPf7eXPvq2wMxZgUhmA1itfxiJUX2ZbU3Mfj4sn646v/",
            toString(r),
            "-",
            toString(s),
            ".mp4"
        ));

        if (r == 0) {
            title = "Orb of Light";
            if (s == 3) {title = "Seeker of Light";}
            category = "Light";
            material = "Fe";
            description = "\'born from ashes raised in shadows seeking light\'";
        } else if (r == 1) {
            title = "Orb of Light";
            if (s == 3) {title = "Carrier of Light";}
            category = "Light";
            material = "Pt";
            description = "\'the one granting the light to others\'";
        } else if (r == 2) {
            title = "Orb of Shadow";
            if (s == 3) {title = "Catcher of Shadow";}
            category = "Shadow";
            material = "Fe";
            description = "\'the ones that hide in shadow must shine\'";
        } else if (r == 3) {
            title = "Orb of Hope";
            if (s == 3) {title = "Apostle of Hope";}
            category = "Hope";
            material = "Fe";
            description = "\'there is light despite all of the darkness\'";
        } else if (r == 4) {
            title = "Orb of Dreams";
            if (s == 3) {title = "Protector of Dreams";}
            category = "Dreams";
            material = "CuSn";
            description = "\'dreams are our realities in waiting\'";
        } else if (r == 5) {
            title = "The Unheard";
            category = "u";
            material = "Ti";
            description = "\'silence speaks louder than words\'";
            imageUrl = "https://gateway.pinata.cloud/ipfs/QmPWX4N5tnWHp9NNmgfaFUfU83JsmtMoyJtmpN9vnSDoS5/5-0.jpg";
            animationUrl = "https://gateway.pinata.cloud/ipfs/QmWoPf7eXPvq2wMxZgUhmA1itfxiJUX2ZbU3Mfj4sn646v/5-0.mp4";
        }

        return metadata(title, category, description, imageUrl, animationUrl, material, "False");
    }

    // CREATE TOKEN URIS //

    function monarchURI(uint id1, uint id2) external pure returns (string memory) {
        metadata memory data = getMonarchMetadata(id1, id2);
        string memory json = string(
            abi.encodePacked( 
                '{"name": "', data.title, '",',
                '"description": "', data.description, '",',
                '"created_by": "artistic_resonance & ktrby",',
                '"image": "', data.imageUrl, '",'
                '"image_url": "', data.imageUrl, '",',
                '"animation": "', data.animationUrl, '",',
                '"animation_url": "', data.animationUrl, '",',
                '"attributes":[',
                '{"trait_type":"Role","value":"', data.title, '"},',
                '{"trait_type":"Material","value":"', data.material, '"},',
                '{"trait_type":"League Monarch","value":"', data.monarch, '"}',
                "]}"
            )
        );

        return string(abi.encodePacked('data:application/json;utf8,', json));
    }

    function tokenURI(uint256 tokenId, uint s) external pure returns (string memory) {
        string memory json; 
        metadata memory data = getMetadata(tokenId, s);
        if (tokenId % 6 == 5) {
            json = string(
                abi.encodePacked( 
                    '{"name": "', data.title, '",',
                    '"description": "', data.description, '",',
                    '"created_by": "artistic_resonance & ktrby",',
                    '"image": "', data.imageUrl, '",'
                    '"image_url": "', data.imageUrl, '",',
                    '"animation": "', data.animationUrl, '",',
                    '"animation_url": "', data.animationUrl, '",',
                    '"attributes":[',
                    '{"trait_type":"Role","value":"', data.title, '"},',
                    '{"trait_type":"Material","value":"', data.material, '"},',
                    '{"trait_type":"League Monarch","value":"', data.monarch, '"}',
                    "]}"
                )
            );
        } else {
            json = string(
                abi.encodePacked( 
                    '{"name": "', data.title, ' | Stage ', toString(s), '",',
                    '"description": "', data.description, '",',
                    '"created_by": "artistic_resonance & ktrby",',
                    '"image": "', data.imageUrl, '",'
                    '"image_url": "', data.imageUrl, '",',
                    '"animation": "', data.animationUrl, '",',
                    '"animation_url": "', data.animationUrl, '",',
                    '"attributes":[',
                    '{"trait_type":"Role","value":"', data.title, '"},',
                    '{"trait_type": "Stage","value":"', toString(s), '"},',
                    '{"trait_type":"Material","value":"', data.material, '"},',
                    '{"trait_type":"League Monarch","value":"', data.monarch, '"}',
                    "]}"
                )
            );
        }
        return string(abi.encodePacked('data:application/json;utf8,', json));
    }

    // Function borrowed from OpenZeppelin Contracts v4.4.1 (utils/Strings.sol) - MIT License
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}