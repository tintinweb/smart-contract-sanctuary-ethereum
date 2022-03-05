// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./erc/165/IERC165.sol";
import "./erc/173/ERC173.sol";
import "./erc/1155/ERC1155.sol";

/**
 * @title Jungle by ESCAPEPLAN smart contract
 */
contract Jungle is ERC1155, ERC173, IERC165 {

    address BigNightRecords = 0x590AfC242d692d6B4b9BD8d69783BFb099E8BCf5;

    constructor() ERC1155("Jungle by ESCAPEPLAN", "JNGL") ERC173(BigNightRecords) {
        _mint(BigNightRecords);
    }

    /**
     * @dev ERC165 supports interface
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165) returns (bool) {
        return
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IERC173).interfaceId ||
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155Metadata).interfaceId ||
            interfaceId == type(IERC1155Receiver).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC165 Interface
 *
 * @dev Interface of the ERC165 standard according to the EIP
 */
interface IERC165 {
    /**
     * @dev ERC165 standard functions
     */

    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC173.sol";

/**
 * @title ERC173 Contract
 *
 * @dev Implementation of the ERC173 standard
 */
contract ERC173 is IERC173 {
    /**
     * @dev ERC173 definitions
     */

    address private _owner;

    /**
     * @dev Prevents function called by non-owner from executing
     */

    modifier ownership() {
        require(owner() == msg.sender, "ERC173: caller is not the owner");

        _;
    }

    /**
     * @dev Sets the deployer as the initial owner
     */

    constructor(address owner_) {
        _transferOwnership(owner_);
    }

    /**
     * @dev ERC173 functions
     */

    function owner() public view virtual override returns (address) {

        return _owner;
    }

    function transferOwnership(address _newOwner) public virtual override ownership {
        _transferOwnership(_newOwner);
    }

    /**
     * @dev ERC173 internal function
     */
    
    function _transferOwnership(address _newOwner) internal virtual {
        address previousOwner = _owner;
        _owner = _newOwner;
    
        emit OwnershipTransferred(previousOwner, _newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./extensions/IERC1155Metadata.sol";
import "./receiver/IERC1155Receiver.sol";

/**
 * @title ERC1155 Contract
 *
 * @dev Implementation of the ERC1155 standard
 */
contract ERC1155 is IERC1155, IERC1155Metadata {
    /**
     * @dev ERC1155 definitions
     */
    mapping(uint256 => mapping(address => uint256)) private _ownerBalance;
    mapping(address => mapping(address => bool)) private _operatorApproval;
    mapping(uint256 => string) private _tokenCid;

    mapping(uint256 => uint256) private _totalSupply;
    uint256 private _currentId = 0;

    string private _name;
    string private _symbol;

    string private cream = "bafybeib2nmrybv2kdntx643gy7npsillmv73jbubjc22vqr5l66slumk64/cream.json";
    string private solidGold = "bafybeihauguddtujyitk6z4hkrtufw3m3g3xewoq3ubh4udxy4nz4giiyu/solid-gold.json";
    string private diamond = "bafybeigweeemhmvj73fcxmxgx6xniuuban4c426m57vbjsndwylsi2yvwu/diamond.json";
    string private trippy = "bafybeiczjwxmqef43bxjhwamyb2icqa2gtau6f63w6wbhjnwqqndebkslq/trippy.json";
    string private deathBot = "bafybeieqmpzipdaih2otzqoq7tcvkecsnaqokghbujmi4ctrkjp3cdoey4/death-bot.json";
    string private dmt = "bafybeiejp5w6ue377vlj33gqttw4qcjxsduycxj3xwnxqztjxkgxc55r2m/dmt.json";
    string private zombie = "bafybeifyzdqglp23mg32cxb7ygzu7v7abv3g2aafmacs7cdt4uacmp4jke/zombie.json";
    string private cheetah = "bafybeifesyui6z7em5acpfy7jddnhkiuk24d6ocsraxfuwlbr5dchirwii/cheetah.json";

    /**
     * @dev Contract name and symbol
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual returns (string memory) {

        return _name;
    }

    function symbol() public view virtual returns (string memory) {

        return _symbol;
    }

    /**
     * @dev Minting functions
     */
    function _mint(address _to) internal virtual {
        _mintTrippy(_to);
        _mintDeathBot(_to);
        _mintDmt(_to);
        _mintZombie(_to);
        _mintCheetah(_to);
        _mintDiamond(_to);
        _mintSolidGold(_to);
        _mintCream(_to);
    }

    function _mintTrippy(address _to) internal virtual {
        _currentId += 1;
        _totalSupply[_currentId] += 1;
        _ownerBalance[_currentId][_to] += 1;
        _tokenCid[_currentId] = trippy;

        emit TransferSingle(msg.sender, address(0), _to, _currentId, _ownerBalance[_currentId][_to]);
    }

    function _mintDeathBot(address _to) internal virtual {
        _currentId += 1;
        _totalSupply[_currentId] += 1;
        _ownerBalance[_currentId][_to] += 1;
        _tokenCid[_currentId] = deathBot;

        emit TransferSingle(msg.sender, address(0), _to, _currentId, _ownerBalance[_currentId][_to]);
    }

    function _mintDmt(address _to) internal virtual {
        _currentId += 1;
        _totalSupply[_currentId] += 1;
        _ownerBalance[_currentId][_to] += 1;
        _tokenCid[_currentId] = dmt;

        emit TransferSingle(msg.sender, address(0), _to, _currentId, _ownerBalance[_currentId][_to]);
    }

    function _mintZombie(address _to) internal virtual {
        _currentId += 1;
        _totalSupply[_currentId] += 1;
        _ownerBalance[_currentId][_to] += 1;
        _tokenCid[_currentId] = zombie;

        emit TransferSingle(msg.sender, address(0), _to, _currentId, _ownerBalance[_currentId][_to]);
    }

    function _mintCheetah(address _to) internal virtual {
        _currentId += 1;
        _totalSupply[_currentId] += 1;
        _ownerBalance[_currentId][_to] += 1;
        _tokenCid[_currentId] = cheetah;

        emit TransferSingle(msg.sender, address(0), _to, _currentId, _ownerBalance[_currentId][_to]);
    }

    function _mintDiamond(address _to) internal virtual {
        _currentId += 1;
        _totalSupply[_currentId] += 15;
        _ownerBalance[_currentId][_to] += 15;
        _tokenCid[_currentId] = diamond;

        emit TransferSingle(msg.sender, address(0), _to, _currentId, _ownerBalance[_currentId][_to]);
    }

    function _mintSolidGold(address _to) internal virtual {
        _currentId += 1;
        _totalSupply[_currentId] += 35;
        _ownerBalance[_currentId][_to] += 35;
        _tokenCid[_currentId] = solidGold;

        emit TransferSingle(msg.sender, address(0), _to, _currentId, _ownerBalance[_currentId][_to]);
    }

    function _mintCream(address _to) internal virtual {
        _currentId += 1;
        _totalSupply[_currentId] += 150;
        _ownerBalance[_currentId][_to] += 150;
        _tokenCid[_currentId] = cream;

        emit TransferSingle(msg.sender, address(0), _to, _currentId, _ownerBalance[_currentId][_to]);
    }

    /**
     * @dev ERC1155Metadata functions
     */
    function _currentTokenId() internal virtual returns (uint256) {

        return _currentId;
    }

    function _baseUri() internal view virtual returns (string memory) {

        return "ipfs://";
    }

    function uri(uint256 _id) public view virtual override returns (string memory) {
        string memory tokenCid = _tokenCid[_id];

        return string(abi.encodePacked(_baseUri(), tokenCid));
    }

    function tokenTotalSupply(uint256 _id) public view virtual returns (uint256) {

        return _totalSupply[_id];
    }

    function totalSupply() public view virtual returns (uint256) {

        return 205;
    }

    /**
     * @dev ERC1155 functions
     */
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes memory _data) public virtual override {
        require(_from == msg.sender || isApprovedForAll(_from, msg.sender), "ERC1155: unauthorized transfer");
        require(_ownerBalance[_id][_from] >= _value, "ERC1155: value exceeds balance");
        require(_to != address(0), "ERC1155: cannot transfer to the zero address");

        _ownerBalance[_id][_from] -= _value;
        _ownerBalance[_id][_to] += _value;

        emit TransferSingle(msg.sender, _from, _to, _id, _value);

        _safeTransferCheck(msg.sender, _from, _to, _id, _value, _data);
    }

    function safeBatchTransferFrom(address _from, address _to, uint256[] memory _ids, uint256[] memory _values, bytes memory _data) public virtual override {
        require(_from == msg.sender || isApprovedForAll(_from, msg.sender), "ERC1155: unauthorized transfer");
        require(_ids.length == _values.length, "ERC1155: ids and amounts length mismatch");
        require(_to != address(0), "ERC1155: cannot transfer to the zero address");

        for (uint256 i = 0; i < _ids.length; ++i) {
            uint256 id = _ids[i];
            uint256 value = _values[i];
            require(_ownerBalance[id][_from] >= value, "ERC1155: insufficient balance for transfer");

            _ownerBalance[id][_from] -= value;
            _ownerBalance[id][_to] += value;
        }

        emit TransferBatch(msg.sender, _from, _to, _ids, _values);

        _safeBatchTransferCheck(msg.sender, _from, _to, _ids, _values, _data);
    }
    
    function balanceOf(address _owner, uint256 _id) public view virtual override returns (uint256) {
        require(_owner != address(0), "ERC1155: cannot get balance for the zero address");

        return _ownerBalance[_id][_owner];
    }

    function balanceOfBatch(address[] memory _owners, uint256[] memory _ids) public view virtual override returns (uint256[] memory) {
        require(_owners.length == _ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](_owners.length);

        for (uint256 i = 0; i < _owners.length; ++i) {
            batchBalances[i] = balanceOf(_owners[i], _ids[i]);
        }

        return batchBalances;
    }

    function setApprovalForAll(address _operator, bool _approved) public virtual override {
        require(msg.sender != _operator, "ERC1155: cannot set approval for self");

        _operatorApproval[msg.sender][_operator] = _approved;

        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function isApprovedForAll(address _owner, address _operator) public view virtual override returns (bool) {

        return _operatorApproval[_owner][_operator];
    }

    /**
     * @dev ERC1155Receiver functions
     */
    function _safeTransferCheck(address _operator, address _from, address _to, uint256 _id, uint256 _value, bytes memory _data) private {
        uint256 size;
        assembly {
            size := extcodesize(_to)
        }
        if (size > 0) {
            try IERC1155Receiver(_to).onERC1155Received(_operator, _from, _id, _value, _data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _safeBatchTransferCheck(address _operator, address _from, address _to, uint256[] memory _ids, uint256[] memory _values, bytes memory _data) private {
        uint256 size;
        assembly {
            size := extcodesize(_to)
        }
        if (size > 0) {
            try IERC1155Receiver(_to).onERC1155BatchReceived(_operator, _from, _ids, _values, _data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC173 Interface
 *
 * @dev Interface of the ERC173 standard according to the EIP
 */
interface IERC173 {
    /**
     * @dev ERC173 standard events
     */

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev ERC173 standard functions
     */

    function owner() view external returns (address);

    function transferOwnership(address _newOwner) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1155 standard as defined in the EIP
 */
interface IERC1155 {
    /**
     * @dev ERC1155 standard events
     */
    event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _value);

    event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _values);

    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    event URI(string _value, uint256 indexed _id);

    /**
     * @dev ERC1155 standard functions
     */
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external;

    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external;

    function balanceOf(address _owner, uint256 _id) external view returns (uint256);

    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory);

    function setApprovalForAll(address _operator, bool _approved) external;

    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface for ERC1155Metadata as defined in the EIP
 */
interface IERC1155Metadata {
    /**
     * @dev ERC1155 token metadata functions
     */
    function uri(uint256 _id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface for ERC1155TokenReceiver as defined in the EIP
 */
interface IERC1155Receiver {
    /**
     * @dev ERC1155Receiver standard functions
     */
    function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _value, bytes calldata _data) external returns(bytes4);

    function onERC1155BatchReceived(address _operator, address _from, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external returns(bytes4);
}