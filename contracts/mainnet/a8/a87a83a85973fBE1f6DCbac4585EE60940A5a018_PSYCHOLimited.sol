// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./interfaces/IPSYCHOLimited.sol";
import "./contracts/Supports.sol";

/**
 * @title PSYCHO Limited
 */
contract PSYCHOLimited is
    IPSYCHOLimited,
    Supports {

    // Avatar generation count
    uint256 private _count = 0;

    /**
     * @dev See {IPSYCHOLimited-active}
     */
    function active(
    ) public view override(
        IPSYCHOLimited
    ) returns (bool) {
        return _active();
    }

    /**
     * @dev See {IPSYCHOLimited-fee}
     */
    function fee(
        uint256 _multiplier
    ) public view override(
        IPSYCHOLimited
    ) returns (uint256) {
        return _fee(_multiplier);
    }

    /**
     * @dev See {IPSYCHOLimited-genesis}
     */
    function genesis(
        uint256 _quantity
    ) public payable override(
        IPSYCHOLimited
    ) {
        if (
            msg.value < _fee(_quantity)
        ) {
            revert PriceNotMet();
        }
        if (
            _active() == false
        ) {
            revert InactiveGenesis();
        }
        if (
            _count + _quantity > 1001 ||
            _quantity > 20
        ) {
            revert ExceedsGenesisLimit();
        }
        _count += _quantity;
        _genesis(msg.sender, _quantity);
    }

    /**
     * @dev See {IPSYCHOLimited-extension}
     */
    function extension(
        uint256 _select,
        uint256 _avatarId,
        string memory _image,
        string memory _animation
    ) public payable override(
        IPSYCHOLimited
    ) {
        if (
            !_isApprovedOrOwner(msg.sender, _avatarId)
        ) {
            revert NonApprovedNonOwner();
        }
        if (
            _select != 0 &&
            msg.sender != owner()
        ) {
            if (
                msg.value < _fee(1)
            ) {
                revert PriceNotMet();
            }
        }
        _extension(_select, _avatarId, _image, _animation);
    }

    /**
     * @dev See {IPSYCHOLimited-metadata}
     */
    function metadata(
        uint256 _avatarId
    ) public view override(
        IPSYCHOLimited
    ) returns (string[4] memory) {
        return _metadata(_avatarId);
    }

    /**
     * @dev See {IPSYCHOLimited-unstoppable}
     */
    function unstoppable(
    ) public view override(
        IPSYCHOLimited
    ) returns (bool) {
        return _unstoppable();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/**
 * @title PSYCHO Limited interface
 */
interface IPSYCHOLimited {
    /**
     * @dev Returns bool
     * Avatar genesis active status
     *
     * `true` active
     * `false` inactive
     */
    function active(
    ) external view returns (bool);

    /**
     * @dev Returns uint256
     * Genesis and extension wei fee multiplied by _quantity
     */
    function fee(
        uint256 _quantity
    ) external view returns (uint256);

    /**
     * @dev Payable transaction
     * Generates up to 20 avatars per purchase
     *
     * Requires minimum `fee(_quantity)` and `active() == true`
     */
    function genesis(
        uint256 _quantity
    ) external payable;

    /**
     * @dev Payable transaction
     * Sets custom URI extension for avatar
     *
     * image _select 1
     * animation _select 2
     * image and animation _select 3
     * reset _select 0
     */
    function extension(
        uint256 _select,
        uint256 _avatarId,
        string memory _image,
        string memory _animation
    ) external payable;

    /**
     * @dev Returns string array
     * The avatar metadata
     *
     * `metadata[0]` image
     * `metadata[1]` animation
     * `metadata[2]` trait
     * `metadata[3]` grade
     */
    function metadata(
        uint256 _avatarId
    ) external view returns (string[4] memory);

    /**
     * @dev Returns bool
     * The contract master power status
     *
     * `false` master can change fee and generate 100 avatars
     * `true` master power relinquished and `fee(_quantity) == 0`
     */
    function unstoppable(
    ) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Master.sol";
import "./Metadata.sol";
import "../interfaces/IERC165.sol";

/**
 * @dev Supports bundle
 */
contract Supports is
    IERC165,
    Metadata,
    Master {

    receive() external payable {}
    fallback() external payable {}

    // Activation variable
    bool private _activeGenesis = false;

    // Lockdown variable
    bool private _locked = false;

    // Wei fee variable
    uint256 private _weiFee = 222000000000000000;

    // Master avatar generation count
    uint256 private _masterCount = 0;

    // Withdraw event
    event Withdraw(address operator, address receiver, uint256 value);

    /**
     * @dev Constructs the Metadata and Master contracts
     */
    constructor(
    ) Metadata(
        "PSYCHO Limited",
        "PSYCHO",
        "ipfs://bafybeidob7iaynjg6h6c3igqnac2qnprlzsfatybuqkxhcizcgpfowwgm4",
        "ipfs://bafybeifqi27soekjrmrgyhrbp3zauxjdpfwi7myiu7iwfveaunzuertdya"
    ) Master(msg.sender) {
        _genesis(msg.sender, 1);
    }

    /**
     * @dev Private contract withdrawal
     */
    function _withdraw(
        address _to
    ) private {
        uint256 balance = address(this).balance;
        (bool success, ) = payable(_to).call{
            value: address(this).balance
        }("");
        require(success, "Ether transfer failed");
        emit Withdraw(msg.sender, _to, balance);
    }

    /**
     * @dev See {IPSYCHOLimited-active}
     */
    function _active(
    ) internal view returns (bool) {
        return _activeGenesis;
    }

    /**
     * @dev See {IPSYCHOLimited-fee}
     */
    function _fee(
        uint256 _multiplier
    ) internal view returns (uint256) {
        return _weiFee * _multiplier;
    }

    /**
     * @dev See {IPSYCHOLimited-unstoppable}
     */
    function _unstoppable(
    ) internal view returns (bool) {
        return _locked;
    }

    /**
     * @dev Relinquishes master role and sets fee to zero
     */
    function relinquish(
        bool _bool
    ) public master {
        require(
            _bool == true
        );
        _weiFee = 0;
        _withdraw(msg.sender);
        _transferOwnership(address(0));
        _locked = true;
    }

    /**
     * @dev Use `true` to activate genesis `false` to deactivate genesis
     */
    function activate(
        bool _bool
    ) public master {
        if (
            _bool == true
        ) {
            _activeGenesis = true;
        }
        else {
            _activeGenesis = false;
        }
    }

    /**
     * @dev Use wei amount to set fee
     */
    function setFee(
        uint256 _wei
    ) public master {
        _weiFee = _wei;
    }

    /**
     * @dev Generates up to 99 avatars for the master
     */
    function masterGenesis(
        address _to,
        uint256 _quantity
    ) public master {
        if (
            _masterCount + _quantity > 99
        ) {
            revert ExceedsGenesisLimit();
        }
        _masterCount += _quantity;
        _genesis(_to, _quantity);
    }

    /**
     * @dev Withdraws ether from contract
     */
    function withdraw(
        address _to
    ) public master {
        _withdraw(_to);
    }

    /**
     * @dev Supports interface
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public pure override(
        IERC165
    ) returns (bool) {
        return
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IERC173).interfaceId ||
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC721Receiver).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "../interfaces/IErrors.sol";
import "../interfaces/IERC173.sol";

/**
 * @dev Implementation of the ERC173 standard
 */
contract Master is
    IERC173,
    IErrors {

    // Master address of contract variable
    address private _master;

    /**
     * @dev Modifier for ownership access
     */
    modifier master(
    ) {
        if (
            owner() != msg.sender
        ) {
            revert CallerIsNonContractOwner();
        }
        _;
    }

    /**
     * @dev Constructs master role
     */
    constructor(
        address owner_
    ) {
        _transferOwnership(owner_);
    }

    /**
     * @dev Returns master of contract
     */
    function owner(
    ) public view override(
        IERC173
    ) returns (address) {
        return _master;
    }

    /**
     * @dev Prevents role transfer to zero address
     */
    function transferOwnership(
        address _newOwner
    ) public override(
        IERC173
    ) master {
        if (
            _newOwner == address(0)
        ) {
            revert TransferToZeroAddress();
        }
        _transferOwnership(_newOwner);
    }

    /**
     * @dev Master role transfer
     */
    function _transferOwnership(
        address _newOwner
    ) internal {
        address previousOwner = _master;
        _master = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./NFT.sol";
import "../interfaces/IERC721Metadata.sol";
import "../libraries/metalib.sol";
import "../libraries/utils.sol";

/**
 * @dev Implementation of the ERC721Metadata standard
 */
contract Metadata is
    NFT,
    IERC721Metadata {

    // Name string variable
    string private _name;

    // Symbol string variable
    string private _symbol;

    // Fallback CID image variable
    string private _defaultImage;

    // Fallback CID animation variable
    string private _defaultAnimation;

    // Mapping token ID to token image
    mapping(uint256 => string) private _tokenImage;

    // Mapping token ID to custom image boolean
    mapping(uint256 => bool) private _customImage;

    // Mapping token ID to token animation
    mapping(uint256 => string) private _tokenAnimation;

    // Mapping token ID to custom animation boolean
    mapping(uint256 => bool) private _customAnimation;

    // Mapping token ID to token description
    mapping(uint256 => string) private _tokenDescription;

    // Mapping token ID to custom description boolean
    mapping(uint256 => bool) private _customDescription;

    /**
     * @dev Constructs the contract metadata and default avatar metadata
     */
    constructor(
        string memory name_,
        string memory symbol_,
        string memory defaultImage_,
        string memory defaultAnimation_
    ) {
        _name = name_;
        _symbol = symbol_;
        _defaultImage = defaultImage_;
        _defaultAnimation = defaultAnimation_;
    }

    /**
     * @dev Name of contract `PSYCHO Limited`
     */
    function name(
    ) public view virtual override(
        IERC721Metadata
    ) returns (string memory) {
        return _name;
    }

    /**
     * @dev Symbol of contract `PSYCHO`
     */
    function symbol(
    ) public view virtual override(
        IERC721Metadata
    ) returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Token URI of token ID
     */
    function tokenURI(
        uint256 _tokenId
    ) public view virtual override(
        IERC721Metadata
    ) returns (string memory) {
        string[2] memory imageAnimation;
        bytes memory dataURI;
        imageAnimation = _imageAnimation(_tokenId);
        if (
            _customImage[_tokenId] == true &&
            _customAnimation[_tokenId] == false
        ) {
            dataURI = abi.encodePacked(
            '{',
                '"name":"PSYCHO Limited #', utils.toString(_tokenId), '",',
                '"description":"', metalib.moods(_meta(_tokenId).mood),
                    ' [', metalib.grades(_meta(_tokenId).grade), ']",',
                '"image":"', imageAnimation[0], '",',
                '"attributes":[',
                    '{',
                        '"trait_type":"Mood",',
                        '"value":"', metalib.moods(_meta(_tokenId).mood), '"',
                    '},',
                    '{',
                        '"trait_type":"Grade",',
                        '"value":"', metalib.grades(_meta(_tokenId).grade), '"',
                    '}',
                ']',
            '}'
            );
        } else {
            dataURI = abi.encodePacked(
            '{',
                '"name":"PSYCHO Limited #', utils.toString(_tokenId), '",',
                '"description":"', metalib.moods(_meta(_tokenId).mood),
                    ' [', metalib.grades(_meta(_tokenId).grade), ']",',
                '"image":"', imageAnimation[0], '",',
                '"animation_url":"', imageAnimation[1], '",',
                '"attributes":[',
                    '{',
                        '"trait_type":"Mood",',
                        '"value":"', metalib.moods(_meta(_tokenId).mood), '"',
                    '},',
                    '{',
                        '"trait_type":"Grade",',
                        '"value":"', metalib.grades(_meta(_tokenId).grade), '"',
                    '}',
                ']',
            '}'
            );
        }
        if (
            !_exists(_tokenId)
        ) {
            return "Invalid ID";
        } else {
            return string(
            abi.encodePacked(
                    "data:application/json;base64,",
                    utils.encode(dataURI)
                )
            );
        }
    }

    /**
     * @dev Image and animation array
     */
    function _imageAnimation(
        uint256 _tokenId
    ) internal view returns (string[2] memory) {
        string memory _uriImage;
        string memory _uriAnimation;
        if (
            _customImage[_tokenId] == true
        ) {
            _uriImage = _tokenImage[_tokenId];
        } else {
            _uriImage = _defaultImage;
        }
        if (
            _customAnimation[_tokenId] == true
        ) {
            _uriAnimation = _tokenAnimation[_tokenId];
        } else {
            _uriAnimation = _defaultAnimation;
        }
        return [_uriImage, _uriAnimation];
    }

    /**
     * @dev See {IPSYCHOLimited-metadata}
     */
    function _metadata(
        uint256 _tokenId
    ) internal view returns (string[4] memory) {
        if (
            !_exists(_tokenId)
        ) {
            string memory message = "Invalid ID";
            return [
                message,
                message,
                message,
                message
            ];
        } else {
            string memory image = _imageAnimation(_tokenId)[0];
            string memory animation = _imageAnimation(_tokenId)[1];
            string memory mood = metalib.moods(_meta(_tokenId).mood);
            string memory grade = metalib.grades(_meta(_tokenId).grade);
            return [
                image,
                animation,
                mood,
                grade
            ];
        }
    }

    /**
     * @dev Sets custom token URI for image
     */
    function _setTokenImage(
        uint256 _tokenId,
        string memory _uri
    ) internal {
        _tokenImage[_tokenId] = _uri;
        _customImage[_tokenId] = true;
    }

    /**
     * @dev Sets custom token URI for animation
     */
    function _setTokenAnimation(
        uint256 _tokenId,
        string memory _uri
    ) internal {
        _tokenAnimation[_tokenId] = _uri;
        _customAnimation[_tokenId] = true;
    }

    /**
     * @dev See {IPSYCHOLimited-extension}
     */
    function _extension(
        uint256 _select,
        uint256 _tokenId,
        string memory _image,
        string memory _animation
    ) internal {
        if (
            _select == 1
        ) {
            _setTokenImage(_tokenId, _image);
        } else if (
            _select == 2
        ) {
            _setTokenAnimation(_tokenId, _animation);
        } else if (
            _select == 3
        ) {
            _tokenImage[_tokenId] = _image;
            _tokenAnimation[_tokenId] = _animation;
            _customImage[_tokenId] = true;
            _customAnimation[_tokenId] = true;
        } else if (
            _select == 0
        ) {
            _reset(_tokenId);
        } else {
            revert NonValidSelection();
        }
    }

    /**
     * @dev See {IPSYCHOLimited-reset}
     */
    function _reset(
        uint256 _tokenId
    ) internal {
        _customImage[_tokenId] = false;
        _customAnimation[_tokenId] = false;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/**
 * @title ERC165 standard
 */
interface IERC165 {
    function supportsInterface(
        bytes4 interfaceId
    ) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/**
 * @title Errors interface
 */
interface IErrors {
    error TransferToZeroAddress();

    error NonApprovedNonOwner();

    error ApproveOwnerAsOperator();

    error TransferFromNonOwner();

    error CallerIsNonContractOwner();

    error InactiveGenesis();

    error ExceedsGenesisLimit();

    error NonValidSelection();

    error PriceNotMet();

    error TransferToNonERC721Receiver();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/**
 * @dev ERC173 standard
 */
interface IERC173 {
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    function owner(
    ) view external returns (address);

    function transferOwnership(
        address _newOwner
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "../interfaces/IErrors.sol";
import "../interfaces/IERC721.sol";
import "../interfaces/IERC721Receiver.sol";

/**
 * @dev Implementation of the ERC721 standard
 */
contract NFT is
    IERC721,
    IErrors {

    // Mapping token ID to owner address
    mapping(uint256 => address) private _tokenOwner;

    // Mapping address to total tokens owned
    mapping(address => uint256) private _ownerBalance;

    // Mapping token ID to approved spender address
    mapping(uint256 => address) private _tokenApproval;

    // Mapping address to approved spender address for all tokens
    mapping(address => mapping(address => bool)) private _operatorApproval;

    // Current token ID variable
    uint256 private _currentIdCount = 0;

    // Mapping token ID to meta struct
    mapping(uint256 => Meta) private _tokenMeta;

    // Meta struct
    struct Meta { 
        uint256 mood;
        uint256 grade;
    }
    Meta meta;

    /**
     * @dev Pseudo number operations
     */
    function _x(
    ) private view returns (uint256) {
        return uint256(
            keccak256(abi.encodePacked(block.timestamp, block.difficulty))
    );}

    function _y(
    ) private view returns (uint256) {
        return uint256(
            keccak256(abi.encodePacked(block.difficulty))
    );}

    function _z(
    ) private view returns (uint256) {
        return uint256(
            keccak256(abi.encodePacked(block.timestamp))
    );}

    function _t(
        uint256 _nonce
    ) private view returns (uint256) {
        return uint256(
            keccak256(abi.encodePacked(_x(), _y(), _nonce))
    ) % 21;}

    function _g(
        uint256 _nonce
    ) private view returns (uint256) {
        return uint256(
            keccak256(abi.encodePacked(_z(), _t(_nonce * 33), _nonce))
    ) % 6;}

    /**
     * @dev Modifier for the total balance
     */
    modifier _totalBalance(
        address _to,
        uint256 _quantity
    ) {
        if (
            _to == address(0)
        ) {
            revert TransferToZeroAddress();
        }
        _ownerBalance[_to] += _quantity;
        _;
    }

    /**
     * @dev Internal loop function for genesis
     */
    function _loop(
        address _to
    ) private {
        _currentIdCount += 1;
        _tokenMeta[_currentIdCount] = Meta(_t(_currentIdCount),
            _g(_currentIdCount));
        _tokenOwner[_currentIdCount] = _to;
        emit Transfer(address(0), _to, _currentIdCount);
    }

    /**
     * @dev Token genesis
     */
    function _genesis(
        address _to,
        uint256 _quantity
    ) internal _totalBalance(
        _to,
        _quantity
    ) {
        for (uint256 i=0; i < _quantity; i++) {
            _loop(_to);
        }
    }

    /**
     * @dev Returns meta struct for token ID
     */
    function _meta(
        uint256 _tokenId
    ) internal view returns (Meta memory) {
        return _tokenMeta[_tokenId];
    }

    /**
     * @dev Returns `true` if token ID exists
     */
    function _exists(
        uint256 _tokenId
    ) internal view virtual returns (bool) {
        return _tokenOwner[_tokenId] != address(0);
    }

    /**
     * @dev Returns total supply
     */
    function totalSupply(
    ) public view returns (uint256) {
        return (_currentIdCount);
    }

    /**
     * @dev Returns owner balance
     */
    function balanceOf(
        address _owner
    ) public view override(
        IERC721
    ) returns (uint256) {
        return _ownerBalance[_owner];
    }

    /**
     * @dev Returns owner of token ID
     */
    function ownerOf(
        uint256 _tokenId
    ) public view override(
        IERC721
    ) returns (address) {
        return _tokenOwner[_tokenId];
    }

    /**
     * @dev Safe transfer from spender address
     */
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public override(
        IERC721
    ) {
        safeTransferFrom(_from, _to, _tokenId, "");
    }

    /**
     * @dev Safe transfer from spender address
     * overload with _transfer
     */
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    ) public override(
        IERC721
    ) {
        if (
            !_isApprovedOrOwner(msg.sender, _tokenId)
        ) {
            revert NonApprovedNonOwner();
        }
        _transfer(_from, _to, _tokenId);
        _onERC721Received(_from, _to, _tokenId, _data);
    }

    /**
     * @dev Transfers tokens from spender address with _transfer
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public override(
        IERC721
    ) {
        if (
            !_isApprovedOrOwner(msg.sender, _tokenId)
        ) {
            revert NonApprovedNonOwner();
        }
        _transfer(_from, _to, _tokenId);
    }

    /**
     * @dev Approves address for spending tokens
     */
    function approve(
        address _approved,
        uint256 _tokenId
    ) public override(
        IERC721
    ) {
        require(
            _tokenOwner[_tokenId] == msg.sender
        );
        _tokenApproval[_tokenId] = _approved;
        emit Approval(msg.sender, _approved, _tokenId);
    }

    /**
     * @dev Allows all tokens to be transferred by approved address
     */
    function setApprovalForAll(
        address _operator,
        bool _approved
    ) public override(
        IERC721
    ) {
        if (
            msg.sender == _operator
        ) {
            revert ApproveOwnerAsOperator();
        }
        _operatorApproval[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    /**
     * @dev Returns approved spender address for token ID
     */
    function getApproved(
        uint256 _tokenId
    ) public view override(
        IERC721
    ) returns (address) {
        return _tokenApproval[_tokenId];
    }

    /**
     * @dev Returns `true` if operator is approved to
     * spend owner tokens
     */
    function isApprovedForAll(
        address _owner,
        address _operator
    ) public view override(
        IERC721
    ) returns (bool) {
        return _operatorApproval[_owner][_operator];
    }

    /**
     * @dev Bool for whether spender is allowed
     */
    function _isApprovedOrOwner(
        address _spender,
        uint256 _tokenId
    ) internal view virtual returns (bool) {
        address tokenOwner = ownerOf(_tokenId);
        return (
            _spender == tokenOwner ||
            isApprovedForAll(tokenOwner, _spender) ||
            getApproved(_tokenId) == _spender
        );
    }

    /**
     * @dev Transfers tokens and emits event
     */
    function _transfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal {
        if (
            ownerOf(_tokenId) != _from
        ) {
            revert TransferFromNonOwner();
        }
        if (
            _to == address(0)
        ) {
            revert TransferToZeroAddress();
        }
        delete _tokenApproval[_tokenId];
        _ownerBalance[_from] -= 1;
        _ownerBalance[_to] += 1;
        _tokenOwner[_tokenId] = _to;
        emit Transfer(_from, _to, _tokenId);
    }

    /**
     * @dev ERC721 receiver
     */
    function _onERC721Received(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (_to.code.length > 0) {
            try IERC721Receiver(_to).onERC721Received(
                msg.sender,
                _from,
                _tokenId,
                _data
            ) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert TransferToNonERC721Receiver();
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/**
 * @title ERC721Metadata standard
 */
interface IERC721Metadata {
    function name(
    ) external view returns (string memory);

    function symbol(
    ) external view returns (string memory);

    function tokenURI(
        uint256 _tokenId
    ) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

library metalib {
    function moods(
        uint256 mood
    ) internal pure returns (string memory) {
        if (mood == 1) {return "Xanxiety";}
        else if (mood == 2) {return "gotcha";}
        else if (mood == 3) {return "RAMBO";}
        else if (mood == 4) {return "Temper";}
        else if (mood == 5) {return "sensitive";}
        else if (mood == 6) {return "Black Ops";}
        else if (mood == 7) {return "cypherpunk";}
        else if (mood == 8) {return "distant memory";}
        else if (mood == 9) {return "CENSORED";}
        else if (mood == 10) {return "Forgive me i have sinned";}
        else if (mood == 11) {return "Special Ops";}
        else if (mood == 12) {return "Agent of terror";}
        else if (mood == 13) {return "Wonderful";}
        else if (mood == 14) {return "3..2..1..";}
        else if (mood == 15) {return "Bulletproof";}
        else if (mood == 16) {return "Maximum capacitance";}
        else if (mood == 17) {return "Sign of God";}
        else if (mood == 18) {return "run";}
        else if (mood == 19) {return "Don't trend on me";}
        else if (mood == 20) {return "Liberator";}
        else {return "Vril";}
    }

    function grades(
        uint256 grade
    ) internal pure returns (string memory) {
        if (grade == 1) {return "2SS";}
        else if (grade == 2) {return "5";}
        else if (grade == 3) {return "V";}
        else if (grade == 4) {return "M";}
        else if (grade == 5) {return "XXX";}
        else {return "Z";}
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

library utils {
    function toString(
        uint256 value
    ) internal pure returns (string memory) {
        if (value == 0) return "0";
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

    string internal constant _TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(
        bytes memory data
    ) internal pure returns (string memory) {
        if (data.length == 0) return "";

        string memory table = _TABLE;

        string memory result = new string(4 * ((data.length + 2) / 3));

        assembly {
            let tablePtr := add(table, 1)

            let resultPtr := add(result, 32)

            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                mstore8(resultPtr, mload(
                    add(tablePtr, and(shr(18, input), 0x3F))
                ))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(
                    add(tablePtr, and(shr(12, input), 0x3F))
                ))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(
                    add(tablePtr, and(shr(6, input), 0x3F))
                ))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(
                    add(tablePtr, and(input, 0x3F))
                ))
                resultPtr := add(resultPtr, 1) // Advance
            }
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/**
 * @title ERC721 standard
 */
interface IERC721 {
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 indexed _tokenId
    );

    event Approval(
        address indexed _owner,
        address indexed _approved,
        uint256 indexed _tokenId
    );

    event ApprovalForAll(
        address indexed _owner,
        address indexed _operator,
        bool _approved
    );

    function balanceOf(
        address _owner
    ) external view returns (uint256);

    function ownerOf(
        uint256 _tokenId
    ) external view returns (address);

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes calldata _data
    ) external;

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external;

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external;

    function approve(
        address _approved,
        uint256 _tokenId
    ) external;

    function setApprovalForAll(
        address _operator,
        bool _approved
    ) external;

    function getApproved(
        uint256 _tokenId
    ) external view returns (address);

    function isApprovedForAll(
        address _owner,
        address _operator
    ) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/**
 * @title ERC721Receiver standard
 */
interface IERC721Receiver {
    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    ) external returns (bytes4);
}