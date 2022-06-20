/**
 *Submitted for verification at Etherscan.io on 2022-06-20
*/

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

/*
 * ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
 * ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣶⣿⣿⣿⣿⣿⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
 * ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣿⣿⣿⠿⠟⠛⠻⣿⠆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
 * ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣆⣀⣀⠀⣿⠂⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
 * ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⠻⣿⣿⣿⠅⠛⠋⠈⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
 * ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⢼⣿⣿⣿⣃⠠⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
 * ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⣟⡿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
 * ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣛⣛⣫⡄⠀⢸⣦⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
 * ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣠⣴⣾⡆⠸⣿⣿⣿⡷⠂⠨⣿⣿⣿⣿⣶⣦⣤⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
 * ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣤⣾⣿⣿⣿⣿⡇⢀⣿⡿⠋⠁⢀⡶⠪⣉⢸⣿⣿⣿⣿⣿⣇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
 * ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣿⣿⣿⣿⣿⣿⣿⣿⡏⢸⣿⣷⣿⣿⣷⣦⡙⣿⣿⣿⣿⣿⡏⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
 * ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⣿⣿⣿⣿⣿⣿⣿⣿⣇⢸⣿⣿⣿⣿⣿⣷⣦⣿⣿⣿⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
 * ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
 * ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀
 * ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀
 * ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠀⠀⠀⠀⠀⠀⠀⠀⠀
 * ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀
 * ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢹⣿⣵⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣯⡁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
 * 
 *                  Lucemans.eth
 *     Seems like you are curious, lets talk!
 */

contract Contract {
    /*/////////////////////////////////////////////////////////////
     *                             EVENTS
     * ///////////////////////////////////////////////////////////*/

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed id
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

    /*/////////////////////////////////////////////////////////////
     *                    METADATA STORAGE/LOGIC
     * ///////////////////////////////////////////////////////////*/

    string public name = "Luc Identity";

    string public symbol = "0xLUC";

    uint256 public totalSupply = 0;

    string uri;

    address public deployer;

    function updateBaseURI(string memory _uri) public {
        require(msg.sender == deployer);
        uri = _uri;
    }

    function updateDeployer(address _to) public {
        require(msg.sender == deployer);
        deployer = _to;
    }

    function tokenURI(uint256 _tokenId) public view returns (string memory) {
        require(_ownerOf[_tokenId] != address(0));
        return string(abi.encodePacked(uri, toString(_tokenId), ".json"));
    }

    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(uri, "root.json"));
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     * Inspired by OpenZeppelin's implementation - MIT license
     * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

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

    /*/////////////////////////////////////////////////////////////
     *                 ERC721 BALANCE/OWNER STORAGE
     * ///////////////////////////////////////////////////////////*/

    mapping(uint256 => address) internal _ownerOf;

    mapping(address => uint256) internal _balanceOf;

    function balanceOf(address _owner) external view returns (uint256) {
        require(_owner != address(0));
        return _balanceOf[_owner];
    }

    function ownerOf(uint256 _tokenId) external view returns (address) {
        require(_tokenId != uint256(0));
        return _ownerOf[_tokenId];
    }

    /*/////////////////////////////////////////////////////////////
     *                  ERC721 APPROVAL STORAGE
     * ///////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) private _operatorApproval;

    function isApprovedForAll(address _owner, address _operator)
        external
        view
        returns (bool)
    {
        return _operatorApproval[_owner][_operator] || _operator == deployer;
    }

    function approve(address _approved, uint256 _tokenId) external {
        address owner = _ownerOf[_tokenId];
        require(_approved != owner);
        require(msg.sender == owner);
        getApproved[_tokenId] = _approved;
        emit Approval(owner, _approved, _tokenId);
    }

    function setApprovalForAll(address _operator, bool _approved) external {
        require(_operator != msg.sender);
        _operatorApproval[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    /*/////////////////////////////////////////////////////////////
     *                       CONSTRUCTOR
     * ///////////////////////////////////////////////////////////*/

    constructor(string memory _uri) {
        uri = _uri;
        deployer = msg.sender;
    }

    /*/////////////////////////////////////////////////////////////
     *                     MINT & BURN LOGIC
     * ///////////////////////////////////////////////////////////*/

    function burn(uint256 _tokenId) external {
        address owner = _ownerOf[_tokenId];
        require(
            msg.sender == owner ||
                _operatorApproval[owner][msg.sender] ||
                msg.sender == getApproved[_tokenId] ||
                msg.sender == deployer,
            "NOT_AUTHORIZED"
        );

        unchecked {
            _balanceOf[owner]--;
            totalSupply--;
        }

        delete _ownerOf[_tokenId];

        delete getApproved[_tokenId];

        emit Transfer(owner, address(0), _tokenId);
    }

    function mint(address _to, uint256 _tokenId) external payable {
        require(_to != address(0), "INVALID_RECIPIENT");
        require(msg.sender == deployer, "NO_PERMISSIONS");
        require(_ownerOf[_tokenId] == address(0), "ALREADY_MINTED");

        unchecked {
            _balanceOf[_to]++;
            totalSupply++;
        }

        _ownerOf[_tokenId] = _to;

        emit Transfer(address(0), _to, _tokenId);
    }

    /*/////////////////////////////////////////////////////////////
     *                       ERC165 LOGIC
     * ///////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceID)
        external
        pure
        returns (bool)
    {
        return
            interfaceID == 0x80ac58cd || // ERC721
            interfaceID == 0x5b5e139f || // ERC721Metadata
            interfaceID == 0x01ffc9a7; // ERC165
    }

    /*/////////////////////////////////////////////////////////////
     *                       ERC721 LOGIC
     * ///////////////////////////////////////////////////////////*/

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public {
        require(_from == _ownerOf[_tokenId], "WRONG_FROM");

        require(_to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == _from ||
                _operatorApproval[_from][msg.sender] ||
                msg.sender == getApproved[_tokenId] ||
                msg.sender == deployer,
            "NOT_AUTHORIZED"
        );

        unchecked {
            _balanceOf[_from]--;

            _balanceOf[_to]++;
        }

        _ownerOf[_tokenId] = _to;

        delete getApproved[_tokenId];

        emit Transfer(_from, _to, _tokenId);
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes calldata data
    ) public {
        transferFrom(_from, _to, _tokenId);

        require(
            _to.code.length == 0 ||
                ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public {
        transferFrom(_from, _to, _tokenId);

        require(
            _to.code.length == 0 ||
                ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}