// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @dao: URN
/// @author: Wizard

import "./Protect.sol";

interface IERC20 {
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract ProtectFactory {
    IERC20 public ash;
    uint256 public price;
    address public wizard;
    address public merge;
    address public pmerge;

    mapping(address => bool) private _protectorAddress;
    mapping(address => bool) private _deniedAddress;
    mapping(address => address) public originalProtector;

    modifier onlyWizard() {
        require(_msgSender() == wizard, "sender is not wizard");
        _;
    }

    constructor(
        uint256 _price,
        address _ash,
        address _merge,
        address _pmerge,
        address _wizard
    ) {
        merge = _merge;
        pmerge = _pmerge;

        wizard = _wizard;

        price = _price;
        ash = IERC20(_ash);
    }

    function isDenied(address _address) public view returns (bool) {
        return _deniedAddress[_address];
    }

    function isProtector(address _address) public view returns (bool) {
        if (isDenied(_address)) return false;
        return _protectorAddress[_address];
    }

    function setWizard(address _wizard) public onlyWizard {
        wizard = _wizard;
    }

    function setDenyListAddress(address _address, bool status)
        public
        onlyWizard
    {
        _deniedAddress[_address] = status;
    }

    function setPrice(uint256 _price) public onlyWizard {
        price = _price;
    }

    function deploy() public returns (address) {
        require(
            ash.allowance(_msgSender(), address(this)) >= price,
            "allowance of ash failed"
        );

        require(
            ash.transferFrom(_msgSender(), wizard, price),
            "transfer of ash failed"
        );

        address protect = address(new Protect(merge, pmerge));
        originalProtector[_msgSender()] = protect;
        _protectorAddress[protect] = true;

        return protect;
    }

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @dao: URN
/// @author: Wizard

import "./IMerge.sol";

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

interface IPMerge is IERC165 {
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function mint(address operator, address to) external returns (uint256);

    function burn(uint256 tokenId) external returns (bool);
}

contract Protect is IERC721Receiver {
    IMerge public merge;
    IPMerge public pMerge;
    uint256 public protectId;
    uint256 public mergeId;

    event Received(address from, uint256 tokenId, uint256 mass);

    constructor(address _merge, address _pmerge) {
        merge = IMerge(_merge);
        pMerge = IPMerge(_pmerge);
    }

    modifier holdsProtectedToken() {
        require(owner() == _msgSender(), "not owner of protected token");
        _;
    }

    function value() public view returns (uint256) {
        return merge.getValueOf(mergeId);
    }

    function mass() public view returns (uint256) {
        return merge.decodeMass(value());
    }

    function class() public view returns (uint256) {
        return merge.decodeClass(value());
    }

    function mergeCount() public view returns (uint256) {
        return merge.getMergeCount(value());
    }

    function tokenUri() public view returns (string memory) {
        return merge.tokenURI(mergeId);
    }

    function transfer(address to, uint256 tokenId)
        public
        virtual
        holdsProtectedToken
    {
        protectId = 0;
        mergeId = 0;
        require(pMerge.burn(tokenId), "failed to burn wrapped merge");
        merge.transferFrom(address(this), to, tokenId);
    }

    function owner() public view virtual returns (address) {
        return pMerge.ownerOf(protectId);
    }

    function onERC721Received(
        address _operator,
        address from,
        uint256 tokenId,
        bytes calldata _data
    ) public virtual override returns (bytes4) {
        // verify only merge tokens are sent
        require(msg.sender == address(merge), "only send merge");

        if (protectId == 0) {
            // if pmerge has not been minted, mint
            uint256 _protectId = pMerge.mint(address(this), from);
            protectId = _protectId;
        } else {
            // verify only the owner can send tokens to the contracts
            require(owner() == from, "only the owner can merge");
        }

        uint256 massSent = merge.massOf(tokenId);
        uint256 massCurrent = 0;

        if (mergeId > 0) {
            massCurrent = merge.massOf(mergeId);
        }

        if (massSent > massCurrent) {
            mergeId = tokenId;
        }

        emit Received(from, tokenId, massSent);
        return IERC721Receiver.onERC721Received.selector;
    }

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IMerge is IERC165 {
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function massOf(uint256 tokenId) external view returns (uint256);

    function getValueOf(uint256 tokenId) external view returns (uint256 value);

    function decodeMass(uint256 value) external pure returns (uint256 mass);

    function decodeClass(uint256 value) external pure returns (uint256 class);

    function tokenURI(uint256 tokenId) external view returns (string memory);

    function getMergeCount(uint256 tokenId)
        external
        view
        returns (uint256 mergeCount);
}