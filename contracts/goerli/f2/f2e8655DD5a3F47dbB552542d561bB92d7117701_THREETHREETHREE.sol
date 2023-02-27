// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnershipTransferred(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnershipTransferred(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function transferOwnership(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Minimalist and gas efficient standard ERC1155 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155 {
    /*//////////////////////////////////////////////////////////////
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

    /*//////////////////////////////////////////////////////////////
                             ERC1155 STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => mapping(uint256 => uint256)) public balanceOf;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                             METADATA LOGIC
    //////////////////////////////////////////////////////////////*/

    function uri(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
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
        bytes calldata data
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
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public virtual {
        require(ids.length == amounts.length, "LENGTH_MISMATCH");

        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        // Storing these outside the loop saves ~15 gas per iteration.
        uint256 id;
        uint256 amount;

        for (uint256 i = 0; i < ids.length; ) {
            id = ids[i];
            amount = amounts[i];

            balanceOf[from][id] -= amount;
            balanceOf[to][id] += amount;

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
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

    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids)
        public
        view
        virtual
        returns (uint256[] memory balances)
    {
        require(owners.length == ids.length, "LENGTH_MISMATCH");

        balances = new uint256[](owners.length);

        // Unchecked because the only math done is incrementing
        // the array index counter which cannot possibly overflow.
        unchecked {
            for (uint256 i = 0; i < owners.length; ++i) {
                balances[i] = balanceOf[owners[i]][ids[i]];
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
            interfaceId == 0x0e89341c; // ERC165 Interface ID for ERC1155MetadataURI
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
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
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[to][ids[i]] += amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
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
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[from][ids[i]] -= amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, address(0), ids, amounts);
    }

    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        balanceOf[from][id] -= amount;

        emit TransferSingle(msg.sender, from, address(0), id, amount);
    }
}

/// @notice A generic interface for a contract which properly accepts ERC1155 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155TokenReceiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private locked = 1;

    modifier nonReentrant() virtual {
        require(locked == 1, "REENTRANCY");

        locked = 2;

        _;

        locked = 1;
    }
}

// SPDX-License-Identifier: UNLICENSED

/// @title THREETHREETHREE
/// @author M1LL1P3D3
/// @notice MAKE THE MAGIC YOU WANT TO SEE IN THE WORLD! ✦✦✦
/// @dev This contract is constructed for use with the FIRSTTHREAD receipt contract.

pragma solidity ^0.8.17;

import "solmate/tokens/ERC1155.sol";
import "solmate/auth/Owned.sol";
import "solmate/utils/ReentrancyGuard.sol";

contract THREETHREETHREE is ERC1155, Owned, ReentrancyGuard {

    string public name = "THREETHREETHREE";
    string public symbol = "333";
    string private _uri;
    /// @dev Global per token supply cap, dualy a mint cap as once the supply decreases more tokens can't be minted.
    uint public constant MAX_SUPPLY_PER_TOKEN = 111;
    /// @dev The address of the receipt contract which may call burn functions in order to issue receipts.
    address public receiptContract;

    /// @dev Struct to hold the definition of a token.
    struct Token {
        /// @dev Name of token consumed by receipt contract for onchain receipt generation.
        string name;
        /// @dev The current supply of the token, initialized to 0 and incremented by mint functions.
        uint currentSupply;
        /// @dev The price of a single token represented in wei.
        uint etherPrice;
        /// @dev Whether the token is active or not, initialized to false and set to true by an admin function.
        bool mintActive;
    }

    /// @dev Mapping of uint token IDs to token definitions.
    mapping(uint => Token) public tokens;

    /// @dev Initializes token definitions with names, and ether prices.
    constructor() Owned(msg.sender) {       
        tokens[0].name = "FRANKINCENSE";
        tokens[1].name = "MYRRH";
        tokens[2].name = "GOLD";
        tokens[0].etherPrice = 0.001 ether;
        tokens[1].etherPrice = 0.002 ether;
        tokens[2].etherPrice = 0.003 ether;
    }

    /// @notice Modifier restricting burn function access to the receipt contract.
    /// @dev Checks that the address calling the burn function is a contract and not a user wallet by comparing the msg.sender to the tx.origin.
    modifier onlyReceiptContract() {
        require(msg.sender == receiptContract, "THREETHREETHREE: Only receipt contract can call this function");
        _;
    }

    /// @notice Mint an amount of up to the remaing supply of a single token.
    /// @param id The ID of the token to mint.
    /// @param amount The amount of tokens to mint.
    function mintSingle(
        uint id,
        uint amount
    ) public payable nonReentrant {
        require(tokens[id].mintActive, "THREETHREETHREE: Minting is not active");
        require(msg.value == amount * tokens[id].etherPrice, "THREETHREETHREE: msg.value is incorrect for the tokens being minted");
        require(tokens[id].currentSupply + amount <= MAX_SUPPLY_PER_TOKEN, "THREETHREETHREE: Max supply reached of the token being minted");
        _mint(msg.sender, id, amount, "");
        tokens[id].currentSupply += amount;
    }

    /// @notice Mint an amount of up to the remaining supply of multiple tokens.
    /// @param ids The IDs of the tokens to mint.
    /// @param amounts The amounts of tokens to mint.
    function mintBatch(
        uint[] memory ids,
        uint[] memory amounts
    ) external payable nonReentrant {
        require(ids.length == amounts.length, "THREETHREETHREE: IDs and amounts arrays must be the same length");
        uint totalEtherPrice;
        for (uint i = 0; i < ids.length; i++) {
            require(tokens[ids[i]].mintActive, "THREETHREETHREE: Minting is not active");
            require(tokens[ids[i]].currentSupply + amounts[i] <= MAX_SUPPLY_PER_TOKEN, "THREETHREETHREE: Max supply reached of the token being minted");
            totalEtherPrice += amounts[i] * tokens[ids[i]].etherPrice;
        }
        require(msg.value == totalEtherPrice, "THREETHREETHREE: msg.value is incorrect for the tokens being minted");
        _batchMint(msg.sender, ids, amounts, "");
        for (uint i = 0; i < ids.length; i++) {
            tokens[ids[i]].currentSupply += amounts[i];
        }
    }

    /// @notice Burn an amount of a single token as receipt contract.
    /// @param from The address to burn tokens from.
    /// @param id The ID of the token to burn.
    /// @param amount The amount of tokens to burn.
    function burnSingle(
        address from,
        uint id,
        uint amount
    ) external onlyReceiptContract {
        require(balanceOf[from][id] >= amount, "THREETHREETHREE: The owner of the tokens being burned does not have the amount of tokens being burned");
        _burn(from, id, amount);
    }

    /// @notice Burn multiple amounts of multiple tokens as receipt contract.
    /// @param from The address to burn tokens from.
    /// @param ids The IDs of the tokens to burn.
    /// @param amounts The amounts of tokens to burn.
    function burnBatch(
        address from,
        uint[] memory ids,
        uint[] memory amounts
    ) external onlyReceiptContract {
        require(ids.length == amounts.length, "THREETHREETHREE: IDs and amounts arrays must be the same length");
        for (uint i = 0; i < ids.length; i++) {
            require(balanceOf[from][ids[i]] >= amounts[i], "THREETHREETHREE: The owner of the tokens being burned does not have the amount of tokens being burned");
        }
        _batchBurn(from, ids, amounts);
    }

    /// @notice Get the URI of a token.
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /// @notice Owner can flip the minting status of a token.
    /// @param id The ID of the token to flip the minting status of.
    function flipTokenMintActive(
        uint id
    ) external onlyOwner {
        require(id < 3, "THREETHREETHREE: NONEXISTENT_TOKEN");
        tokens[id].mintActive = !tokens[id].mintActive;
    }

    /// @notice Owner can set the name of a token.
    /// @param id The ID of the token to set the name of.
    /// @param _name The name to set the token to.
    function setTokenName(
        uint id,
        string calldata _name
    ) external onlyOwner {
        require(id < 3, "THREETHREETHREE: NONEXISTENT_TOKEN");
        tokens[id].name = _name;
    }
    
    
    /// @notice Owner can set the URI of a token.
    /// @param newuri The URI to set for the contract.
    function setURI(
        string memory newuri
    ) external onlyOwner {
        _uri = newuri;
    }
    
    /// @notice Owner can set the receipt contract address.
    /// @param _receiptContract The address of the receipt contract.
    function setReceiptContract(
        address _receiptContract
    ) external onlyOwner {
        receiptContract = _receiptContract;
    }

    /// @notice Owner can withdraw all ether from contract
    function withdrawEther() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

}