// SPDX-License-Identifier: MIT
//
// EIP-1167: Minimal Proxy Contract
// https://eips.ethereum.org/EIPS/eip-1167
//
// Derived from OpenZeppelin Contracts (proxy/Clones.sol)
// https://github.com/OpenZeppelin/openzeppelin-contracts/tree/master/contracts/proxy/Clones.sol
//
//       ___           ___         ___           ___              ___           ___                     ___
//      /  /\         /  /\       /  /\         /__/\            /__/\         /  /\        ___        /  /\
//     /  /::\       /  /::\     /  /:/_        \  \:\           \  \:\       /  /:/_      /  /\      /  /:/_
//    /  /:/\:\     /  /:/\:\   /  /:/ /\        \  \:\           \  \:\     /  /:/ /\    /  /:/     /  /:/ /\
//   /  /:/  \:\   /  /:/~/:/  /  /:/ /:/_   _____\__\:\      _____\__\:\   /  /:/ /:/   /  /:/     /  /:/ /::\
//  /__/:/ \__\:\ /__/:/ /:/  /__/:/ /:/ /\ /__/::::::::\    /__/::::::::\ /__/:/ /:/   /  /::\    /__/:/ /:/\:\
//  \  \:\ /  /:/ \  \:\/:/   \  \:\/:/ /:/ \  \:\~~\~~\/    \  \:\~~\~~\/ \  \:\/:/   /__/:/\:\   \  \:\/:/~/:/
//   \  \:\  /:/   \  \::/     \  \::/ /:/   \  \:\  ~~~      \  \:\  ~~~   \  \::/    \__\/  \:\   \  \::/ /:/
//    \  \:\/:/     \  \:\      \  \:\/:/     \  \:\           \  \:\        \  \:\         \  \:\   \__\/ /:/
//     \  \::/       \  \:\      \  \::/       \  \:\           \  \:\        \  \:\         \__\/     /__/:/
//      \__\/         \__\/       \__\/         \__\/            \__\/         \__\/                   \__\/
//
//
//   OpenERC165
//        |
//   OpenCloner —— IOpenCloner
//
pragma solidity 0.8.9;

import "OpenNFTs/contracts/interfaces/IOpenCloner.sol";
import "OpenNFTs/contracts/OpenERC/OpenERC165.sol";

abstract contract OpenCloner is IOpenCloner, OpenERC165 {
    /// @notice Clone template (via EIP-1167)
    /// @param  template_ : template address
    /// @return clone_ : clone address
    function clone(address template_) public virtual returns (address clone_) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, template_))
            mstore(
                add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            clone_ := create(0, ptr, 0x37)
        }
        assert(clone_ != address(0));
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override (OpenERC165)
        returns (bool)
    {
        return interfaceId == type(IOpenCloner).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
//
// EIP-165: Standard Interface Detection
// https://eips.ethereum.org/EIPS/eip-165
//
// Derived from OpenZeppelin Contracts (utils/introspection/ERC165.sol)
// https://github.com/OpenZeppelin/openzeppelin-contracts/tree/master/contracts/utils/introspection/ERC165.sol
//
//       ___           ___         ___           ___              ___           ___                     ___
//      /  /\         /  /\       /  /\         /__/\            /__/\         /  /\        ___        /  /\
//     /  /::\       /  /::\     /  /:/_        \  \:\           \  \:\       /  /:/_      /  /\      /  /:/_
//    /  /:/\:\     /  /:/\:\   /  /:/ /\        \  \:\           \  \:\     /  /:/ /\    /  /:/     /  /:/ /\
//   /  /:/  \:\   /  /:/~/:/  /  /:/ /:/_   _____\__\:\      _____\__\:\   /  /:/ /:/   /  /:/     /  /:/ /::\
//  /__/:/ \__\:\ /__/:/ /:/  /__/:/ /:/ /\ /__/::::::::\    /__/::::::::\ /__/:/ /:/   /  /::\    /__/:/ /:/\:\
//  \  \:\ /  /:/ \  \:\/:/   \  \:\/:/ /:/ \  \:\~~\~~\/    \  \:\~~\~~\/ \  \:\/:/   /__/:/\:\   \  \:\/:/~/:/
//   \  \:\  /:/   \  \::/     \  \::/ /:/   \  \:\  ~~~      \  \:\  ~~~   \  \::/    \__\/  \:\   \  \::/ /:/
//    \  \:\/:/     \  \:\      \  \:\/:/     \  \:\           \  \:\        \  \:\         \  \:\   \__\/ /:/
//     \  \::/       \  \:\      \  \::/       \  \:\           \  \:\        \  \:\         \__\/     /__/:/
//      \__\/         \__\/       \__\/         \__\/            \__\/         \__\/                   \__\/
//
//  OpenERC165 —— IERC165
//
pragma solidity 0.8.9;

import "OpenNFTs/contracts/interfaces/IERC165.sol";

abstract contract OpenERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == 0x01ffc9a7; //  type(IERC165).interfaceId
    }
}

// SPDX-License-Identifier: MIT
//
// EIP-173: Contract Ownership Standard
// https://eips.ethereum.org/EIPS/eip-173
//
// Derived from OpenZeppelin Contracts (access/Ownable.sol)
// https://github.com/OpenZeppelin/openzeppelin-contracts/tree/master/contracts/access/Ownable.sol
//
//       ___           ___         ___           ___              ___           ___                     ___
//      /  /\         /  /\       /  /\         /__/\            /__/\         /  /\        ___        /  /\
//     /  /::\       /  /::\     /  /:/_        \  \:\           \  \:\       /  /:/_      /  /\      /  /:/_
//    /  /:/\:\     /  /:/\:\   /  /:/ /\        \  \:\           \  \:\     /  /:/ /\    /  /:/     /  /:/ /\
//   /  /:/  \:\   /  /:/~/:/  /  /:/ /:/_   _____\__\:\      _____\__\:\   /  /:/ /:/   /  /:/     /  /:/ /::\
//  /__/:/ \__\:\ /__/:/ /:/  /__/:/ /:/ /\ /__/::::::::\    /__/::::::::\ /__/:/ /:/   /  /::\    /__/:/ /:/\:\
//  \  \:\ /  /:/ \  \:\/:/   \  \:\/:/ /:/ \  \:\~~\~~\/    \  \:\~~\~~\/ \  \:\/:/   /__/:/\:\   \  \:\/:/~/:/
//   \  \:\  /:/   \  \::/     \  \::/ /:/   \  \:\  ~~~      \  \:\  ~~~   \  \::/    \__\/  \:\   \  \::/ /:/
//    \  \:\/:/     \  \:\      \  \:\/:/     \  \:\           \  \:\        \  \:\         \  \:\   \__\/ /:/
//     \  \::/       \  \:\      \  \::/       \  \:\           \  \:\        \  \:\         \__\/     /__/:/
//      \__\/         \__\/       \__\/         \__\/            \__\/         \__\/                   \__\/
//
//  OpenERC165
//       |
//  OpenERC173 —— IERC173
//
pragma solidity 0.8.9;

import "OpenNFTs/contracts/OpenERC/OpenERC165.sol";
import "OpenNFTs/contracts/interfaces/IERC173.sol";

abstract contract OpenERC173 is IERC173, OpenERC165 {
    bool private _openERC173Initialized;
    address private _owner;

    modifier onlyOwner() {
        require(_owner == msg.sender, "Not owner");
        _;
    }

    function transferOwnership(address newOwner) external override (IERC173) onlyOwner {
        _transferOwnership(newOwner);
    }

    function owner() public view override (IERC173) returns (address) {
        return _owner;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override (OpenERC165)
        returns (bool)
    {
        return interfaceId == 0x7f5828d0 || super.supportsInterface(interfaceId);
    }

    function _initialize(address owner_) internal {
        require(_openERC173Initialized == false, "Already initialized");
        _openERC173Initialized = true;

        _transferOwnership(owner_);
    }

    function _transferOwnership(address newOwner) internal {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IERC173 {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function transferOwnership(address newOwner) external;

    function owner() external view returns (address currentOwner);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IOpenCloneable {
    function initialize(
        string memory name,
        string memory symbol,
        address owner,
        bytes memory params
    ) external;

    function initialized() external view returns (bool);

    function template() external view returns (string memory);

    function version() external view returns (uint256);

    function parent() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IOpenCloner {
    function clone(address template) external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IOpenRegistry {
    function setRegisterer(address registerer) external;

    function removeAddress(address addr) external;

    function addAddress(address addr) external;

    function addAddresses(address[] memory addrs) external;

    function getAddresses() external view returns (address[] memory);

    function registerer() external view returns (address);

    function countAddresses() external view returns (uint256);

    function isRegistered(address addr) external view returns (bool registered);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IOpenAutoMarket {
    function mint(string memory tokenURI) external returns (uint256 tokenID);

    function mint(
        address minter,
        string memory tokenURI,
        uint256 price,
        address receiver,
        uint96 fee
    ) external payable returns (uint256 tokenID);

    function gift(address to, uint256 tokenID) external payable;

    function buy(uint256 tokenID) external payable;

    function open() external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IOpenNFTsFactoryV3 {
    event Clone(string indexed templateName, address indexed clone, string indexed name, string symbol);

    event SetResolver(address indexed resolver);

    event SetTemplate(string indexed templateName, address indexed template, uint256 index);

    function setResolver(address resolver) external;

    function setTreasury(address treasury, uint96 treasuryFee) external;

    function setTemplate(string memory templateName, address template) external;

    function clone(
        string memory name,
        string memory symbol,
        string memory templateName,
        bytes memory params
    ) external returns (address);

    function template(string memory templateName) external view returns (address);

    function templates(uint256 num) external view returns (address);

    function countTemplates() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IOpenNFTsV4 {
    function mint(string memory tokenURI) external returns (uint256 tokenID);

    function mint(address minter, string memory tokenURI) external returns (uint256 tokenID);

    function burn(uint256 tokenID) external;

    function open() external view returns (bool);
}

// SPDX-License-Identifier: MIT
//
// Derived from Kredeum NFTs
// https://github.com/Kredeum/kredeum
//
//       ___           ___         ___           ___                    ___           ___                     ___
//      /  /\         /  /\       /  /\         /__/\                  /__/\         /  /\        ___        /  /\
//     /  /::\       /  /::\     /  /:/_        \  \:\                 \  \:\       /  /:/_      /  /\      /  /:/_
//    /  /:/\:\     /  /:/\:\   /  /:/ /\        \  \:\                 \  \:\     /  /:/ /\    /  /:/     /  /:/ /\
//   /  /:/  \:\   /  /:/~/:/  /  /:/ /:/_   _____\__\:\            _____\__\:\   /  /:/ /:/   /  /:/     /  /:/ /::\
//  /__/:/ \__\:\ /__/:/ /:/  /__/:/ /:/ /\ /__/::::::::\          /__/::::::::\ /__/:/ /:/   /  /::\    /__/:/ /:/\:\
//  \  \:\ /  /:/ \  \:\/:/   \  \:\/:/ /:/ \  \:\~~\~~\/          \  \:\~~\~~\/ \  \:\/:/   /__/:/\:\   \  \:\/:/~/:/
//   \  \:\  /:/   \  \::/     \  \::/ /:/   \  \:\  ~~~            \  \:\  ~~~   \  \::/    \__\/  \:\   \  \::/ /:/
//    \  \:\/:/     \  \:\      \  \:\/:/     \  \:\                 \  \:\        \  \:\         \  \:\   \__\/ /:/
//     \  \::/       \  \:\      \  \::/       \  \:\                 \  \:\        \  \:\         \__\/     /__/:/
//      \__\/         \__\/       \__\/         \__\/                  \__\/         \__\/                   \__\/
//
//
//   OpenERC165
//   (supports)
//       |
//       ———————————————————————
//       |        |            |
//       |   OpenERC173    OpenCloner
//       |    (ownable)        |
//       |        |            |
//       ———————————————————————
//       |
// OpenNFTsFactoryV3 —— IOpenNFTsFactoryV3
//
pragma solidity ^0.8.9;

import "OpenNFTs/contracts/OpenERC/OpenERC173.sol";
import "OpenNFTs/contracts/OpenCloner/OpenCloner.sol";

import "OpenNFTs/contracts/interfaces/IERC165.sol";
import "OpenNFTs/contracts/interfaces/IOpenCloneable.sol";
import "OpenNFTs/contracts/interfaces/IOpenRegistry.sol";
import "../interfaces/IOpenNFTsFactoryV3.sol";
import "../interfaces/IOpenNFTsV4.sol";
import "../interfaces/IOpenAutoMarket.sol";

/// @title OpenNFTsFactoryV3 smartcontract
/// @notice Factory for NFTs contracts: ERC721 or ERC1155
/// @notice Create new NFTs Collections smartcontracts by cloning templates
contract OpenNFTsFactoryV3 is IOpenNFTsFactoryV3, OpenERC173, OpenCloner {
    /// @notice Named Templates

    mapping(string => uint256) private _numTemplates;
    address[] public templates;

    address public nftsResolver;

    address private _treasury;
    uint96 private _treasuryFee;

    constructor(
        address initialOwner_,
        address treasury_,
        uint96 treasuryFee_
    ) {
        OpenERC173._transferOwnership(initialOwner_);
        setTreasury(treasury_, treasuryFee_);
    }

    /// @notice clone template
    /// @param name name of Clone collection
    /// @param symbol symbol of Clone collection
    /// @return clone_ Address of Clone collection
    function clone(
        string memory name,
        string memory symbol,
        string memory templateName,
        bytes memory params
    ) external override(IOpenNFTsFactoryV3) returns (address clone_) {
        clone_ = clone(template(templateName));

        IOpenCloneable(clone_).initialize(name, symbol, msg.sender, abi.encode(params, _treasury, _treasuryFee));

        IOpenRegistry(nftsResolver).addAddress(clone_);

        emit Clone(templateName, clone_, name, symbol);
    }

    function countTemplates() external view override(IOpenNFTsFactoryV3) returns (uint256 count) {
        count = templates.length;
    }

    function setTreasury(address treasury_, uint96 treasuryFee_) public override(IOpenNFTsFactoryV3) onlyOwner {
        _treasury = treasury_;
        _treasuryFee = treasuryFee_;
    }

    function setResolver(address resolver_) public override(IOpenNFTsFactoryV3) onlyOwner {
        nftsResolver = resolver_;

        emit SetResolver(nftsResolver);
    }

    /// @notice Set Template by Name
    /// @param templateName_ Name of the template
    /// @param template_ Address of the template
    function setTemplate(string memory templateName_, address template_) public override(IOpenNFTsFactoryV3) onlyOwner {
        require(IERC165(template_).supportsInterface(type(IOpenCloneable).interfaceId), "Not OpenCloneable");
        require(IOpenCloneable(template_).initialized(), "Not initialized");
        require(template_.code.length != 45, "Clone not valid template");

        uint256 num = _numTemplates[templateName_];
        if (num >= 1) {
            templates[num - 1] = template_;
        } else {
            templates.push(template_);
            num = templates.length;

            _numTemplates[templateName_] = num;
        }

        IOpenRegistry(nftsResolver).addAddress(template_);

        emit SetTemplate(templateName_, template_, num);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(OpenERC173, OpenCloner) returns (bool) {
        return interfaceId == type(IOpenNFTsFactoryV3).interfaceId || super.supportsInterface(interfaceId);
    }

    /// @notice Get Template
    /// @param  templateName : template name
    /// @return template_ : template address
    function template(string memory templateName) public view override(IOpenNFTsFactoryV3) returns (address template_) {
        uint256 num = _numTemplates[templateName];
        require(num >= 1, "Invalid Template");

        template_ = templates[num - 1];
        require(template_ != address(0), "No Template");
    }
}