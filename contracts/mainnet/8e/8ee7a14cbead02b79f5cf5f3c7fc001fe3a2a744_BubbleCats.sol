// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*

 :P&@@@@@@&BY^                                   .?5?                                           .^!!!^.                                               
 @@@@@@@@@@@@@@P.                  .B&&G.        &@@@&            J##P:                     :Y#@@@@@@@@&G!                       ..                   
[email protected]@@@@[email protected]@@@@@!                 [email protected]@@@#        [email protected]@@@G          [email protected]@@@@~                  ~#@@@@@@&&@@@@@@&~                   ^&@@B                  
:@@@@@    !#@@@@@5                  [email protected]@@@?        #@@@@:          [email protected]@@@&                 [email protected]@@@@&7.   ^&@@@@@.                  [email protected]@@@                  
^@@@@@&@@@@@@@@@@7                   &@@@@        :@@@@B           [email protected]@@@^               #@@@@@Y        JGBG!    .^~^:          #@@@& .:!~.  :JG#&#GJ: 
[email protected]@@@@@@@@@@@@@@@@@G^                [email protected]@@@?        #@@@@.          [email protected]@@@~              [email protected]@@@@J               .5&@@@@@@#PY.  :[email protected]@@@@@@@@@@[email protected]@@@&@@@@G
[email protected]@@@@5J????J5B&@@@@@G   :5GY.  :77: [email protected]@@@&7?~:    [email protected]@@@#GGJ^      [email protected]@@@:   ^JGBBGJ.  :@@@@@#               [email protected]@@@@B#@@@@@[email protected]@@@@@@@@@@&#G~ @@@@:   B#J
[email protected]@@@&          ~&@@@@# [email protected]@@@B  @@@@! &@@@@@@@@&5. ^@@@@@@@@@@J    &@@@@  7&@@@@@@@@? [email protected]@@@@7              :@@@@P  [email protected]@@@@#:#&&#@@@@J       :&@@@#Y^   
[email protected]@@@#            @@@@@[email protected]@@@B .&@@@@ [email protected]@@@#G&@@@@::@@@@@5P&@@@#  :@@@@G [email protected]@@@&  @@@& [email protected]@@@@7              [email protected]@@@[email protected]@@@@@@&    :@@@@!         !P&@@@@G.
[email protected]@@@B           [email protected]@@@@7 &@@@@. [email protected]@@@^[email protected]@@@   [email protected]@@#^@@@@Y   @@@@! [email protected]@@@^[email protected]@@@@@@@@@&: [email protected]@@@@&               [email protected]@@@@@@@[email protected]@@@7   [email protected]@@@7     [email protected]@@   [email protected]@@#
[email protected]@@@G         [email protected]@@@@B  [email protected]@@@@[email protected]@@@&.&@@@@   [email protected]@@[email protected]@@@J  :@@@@: @@@@& [email protected]@@@@      .: [email protected]@@@@&^          ^?Y?7JGBB5~  [email protected]@@&    @@@@G      [email protected]@@@&&@@@@7
[email protected]@@@&Y?777?YG&@@@@@@Y    ^[email protected]@@@@@@B. &@@@@&B&@@@&[email protected]@@@@B#@@@@Y [email protected]@@@?  [email protected]@@@@@@@@@@@. ^&@@@@@&P?!!7JP#@@@@@@.        !YJ.    [email protected]@@@?       !P#&&#G7. 
[email protected]@@@@@@@@@@@@@@@@&J.       .^!??~.   :Y#@@@@@@#?   J#@@@@@@@G:  #@@@@.   .Y#&@@&&#B5^    !#@@@@@@@@@@@@@@@&P~                  [email protected]@@@:                
 :JP#&@@@@@@@&B5!.                       .^~~:        .~?J?^     !&@&7                      .~JG#&&&&&#PJ~.                      :77.                 


    Author: exarch.eth
*/

import "@rari-capital/solmate/src/tokens/ERC1155.sol";
import "@rari-capital/solmate/src/utils/ReentrancyGuard.sol";

contract BubbleCats is ERC1155, ReentrancyGuard {
    string public constant name = "BubbleCats";
    string public constant symbol = "BUBBLE";
    uint256 public constant maxSupply = 303;

    address private _owner;
    string private _baseURI;
    uint256 private _totalSupply;

    constructor() {
        _owner = msg.sender;
    }

    //======================== MODIFIERS ========================

    modifier isOwner() {
        require(_owner == msg.sender, "NOT_OWNER");
        _;
    }

    modifier checkMaxSupply(uint256 num) {
        require(_totalSupply + num <= maxSupply, "MAX_SUPPLY");
        _;
    }

    modifier tokenExists(uint256 tokenId) {
        require(tokenId > 0 && tokenId <= _totalSupply, "NULL_TOKEN");
        _;
    }

    //==================== EXTERNAL FUNCTIONS ====================

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function owner() external view returns (address) {
        return _owner;
    }

    function setOwner(address newOwner) external payable isOwner {
        _owner = newOwner;
    }

    function emergencyWithdraw(address payable to) external payable isOwner {
        to.transfer(address(this).balance);
    }

    function blowBubbles(
        string calldata newURI,
        address to,
        uint256 amount,
        bytes calldata data
    ) external payable isOwner checkMaxSupply(amount) nonReentrant {
        require(amount > 0, "ZERO_AMOUNT");

        setBaseURI(newURI);

        for (uint256 i = 0; i < amount; ) {
            unchecked {
                ++i;
                ++_totalSupply;
            }

            _mint(to, _totalSupply, 1, data);
        }
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        tokenExists(_tokenId)
        returns (address receiver, uint256 royaltyAmount)
    {
        return (address(_owner), (_salePrice * 5) / 100);
    }

    //===================== PUBLIC FUNCTIONS =====================

    function uri(uint256 id)
        public
        view
        override
        tokenExists(id)
        returns (string memory)
    {
        return string(abi.encodePacked(_baseURI, uint2str(id)));
    }

    function setBaseURI(string calldata newURI) public payable isOwner {
        _baseURI = newURI;
        emit URI(newURI, 0);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        pure
        override
        returns (bool)
    {
        return
            interfaceId == 0x2a55205a || super.supportsInterface(interfaceId);
    }

    //==================== INTERNAL FUNCTIONS ====================

    function uint2str(uint256 value) internal pure returns (string memory) {
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Minimalist and gas efficient standard ERC1155 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155 {
    /*///////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 amount
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] amounts
    );

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event URI(string value, uint256 indexed id);

    /*///////////////////////////////////////////////////////////////
                            ERC1155 STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => mapping(uint256 => uint256)) public balanceOf;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*///////////////////////////////////////////////////////////////
                             METADATA LOGIC
    //////////////////////////////////////////////////////////////*/

    function uri(uint256 id) public view virtual returns (string memory);

    /*///////////////////////////////////////////////////////////////
                             ERC1155 LOGIC
    //////////////////////////////////////////////////////////////*/

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual {
        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        balanceOf[from][id] -= amount;
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, from, to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, from, id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        for (uint256 i = 0; i < idsLength; ) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            balanceOf[from][id] -= amount;
            balanceOf[to][id] += amount;

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                i++;
            }
        }

        emit TransferBatch(msg.sender, from, to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, from, ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function balanceOfBatch(address[] memory owners, uint256[] memory ids)
        public
        view
        virtual
        returns (uint256[] memory balances)
    {
        uint256 ownersLength = owners.length; // Saves MLOADs.

        require(ownersLength == ids.length, "LENGTH_MISMATCH");

        balances = new uint256[](owners.length);

        // Unchecked because the only math done is incrementing
        // the array index counter which cannot possibly overflow.
        unchecked {
            for (uint256 i = 0; i < ownersLength; i++) {
                balances[i] = balanceOf[owners[i]][ids[i]];
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public pure virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
            interfaceId == 0x0e89341c; // ERC165 Interface ID for ERC1155MetadataURI
    }

    /*///////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal {
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, address(0), to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, address(0), id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchMint(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[to][ids[i]] += amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                i++;
            }
        }

        emit TransferBatch(msg.sender, address(0), to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, address(0), ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchBurn(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[from][ids[i]] -= amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                i++;
            }
        }

        emit TransferBatch(msg.sender, from, address(0), ids, amounts);
    }

    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal {
        balanceOf[from][id] -= amount;

        emit TransferSingle(msg.sender, from, address(0), id, amount);
    }
}

/// @notice A generic interface for a contract which properly accepts ERC1155 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC1155.sol)
interface ERC1155TokenReceiver {
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external returns (bytes4);

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private reentrancyStatus = 1;

    modifier nonReentrant() {
        require(reentrancyStatus == 1, "REENTRANCY");

        reentrancyStatus = 2;

        _;

        reentrancyStatus = 1;
    }
}