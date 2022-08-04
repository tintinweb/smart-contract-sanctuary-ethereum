/**
 *Submitted for verification at Etherscan.io on 2022-08-04
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IERC20 {
    function mint(address, uint256) external;
    function balanceOf(address) external returns(uint256);
    function transfer(address, uint256) external returns (bool);
}

interface IERC1155 {
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata id,
        uint256[] calldata amount,
        bytes calldata data
    ) external;

    function setApprovalForAll(address, bool) external;
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

contract MockRewards is ERC1155TokenReceiver {
    mapping(uint256 => uint256[]) public cards;
    IERC1155 public parallelAlpha;
    uint256 public endTimestamp;
    IERC20 public PRIME;

    constructor(address _parallelAlpha, address _prime) {
        parallelAlpha = IERC1155(_parallelAlpha);
        PRIME = IERC20(_prime);

        cards[15].push(27);
        cards[15].push(28);
        cards[15].push(29);
        cards[15].push(30);
        cards[15].push(31);
        cards[15].push(33);
        cards[15].push(34);
        cards[15].push(35);
        cards[3].push(10214);
        cards[3].push(10215);
        cards[3].push(10216);
        cards[3].push(10217);
        cards[3].push(10218);
        cards[3].push(10219);
        cards[3].push(10220);
        cards[3].push(10221);
        cards[3].push(10222);
        cards[3].push(10223);
        cards[19].push(10666);
        cards[19].push(10688);
        cards[19].push(10705);
        cards[19].push(10726);
        cards[19].push(10746);
        cards[8].push(10292);
        cards[8].push(10293);
        cards[8].push(10294);
        cards[8].push(10465);
        cards[8].push(10466);
        cards[8].push(10467);
        cards[8].push(10469);
        cards[7].push(10476);
        cards[7].push(10477);
        cards[7].push(10478);
        cards[7].push(10479);
        cards[7].push(10480);
    }

    function cache(uint256 _pid, uint256) public {
        uint256[] memory amounts = new uint256[](cards[_pid].length);
        uint256[] memory ids = new uint256[](cards[_pid].length);
        for (uint256 i = 0; i < amounts.length; i++) {
            amounts[i] = 1;
            ids[i] = cards[_pid][i];
        }

        parallelAlpha.safeBatchTransferFrom(
            msg.sender,
            address(this),
            ids,
            amounts,
            bytes("")
        );
    }

    function withdraw(uint256 _pid, uint256 _amount) public {
        uint256[] memory amounts = new uint256[](cards[_pid].length);
        uint256[] memory ids = new uint256[](cards[_pid].length);
        for (uint256 i = 0; i < amounts.length; i++) {
            amounts[i] = 1;
            ids[i] = cards[_pid][i];
        }

        parallelAlpha.safeBatchTransferFrom(
            address(this),
            msg.sender,
            ids,
            amounts,
            bytes("")
        );
    }

    function getPoolTokenIds(uint256 _pid) public view returns(uint256[] memory) {
        return cards[_pid];
    }

    function claimPrime(uint256 _pid) public {
        PRIME.mint(msg.sender, 100000);
    }

    function setEndTimestamp(uint256 _time) public {
        endTimestamp = _time;
    }

    /// @notice Handles the receipt of a single ERC1155 token type
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external virtual override returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155Received.selector;
    }

    /// @notice Handles the receipt of multiple ERC1155 token types
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external virtual override returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155BatchReceived.selector;
    }
}