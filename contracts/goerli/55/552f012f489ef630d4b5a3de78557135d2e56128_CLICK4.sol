/**
 *Submitted for verification at Etherscan.io on 2022-08-23
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

pragma solidity ^0.8.0;

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

interface NFT {
    function mint(uint256 mints) external payable;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function tokensByOwner(address account) external view returns (uint256[] memory);
}

contract CLICK4 is Ownable, ERC721Holder {

    struct Player {
        address player;
        uint256 clicks;
        uint256 cooldown;
    }

    bool public live;
    uint256 public startTimestamp;
    uint256 public players;
    uint256 public oneMinute;
    uint256 public oneWeek;
    uint256 public mints;
    bool public withdrew;
    address public winner;
    address public nft;

    receive() external payable{}

    constructor(address _nft) {
        nft = _nft;
        oneMinute = 60;
        oneWeek = 604800;
    }

    mapping(uint256 => Player) public allPlayers;
    mapping(address => bool) public activePlayer;
    mapping(uint256 => address) public playerByNumber;
    mapping(address => uint256) public numberByAddress;
    
    event Click(address account, uint256 clicks);
    event Mint(address winner, uint256 mintNumber);
    event Withdraw(address winner, uint256 winnings);
    
    function startGame() public onlyOwner {
        live = true;
        startTimestamp = block.timestamp;
    }

    function endGame() public onlyOwner {
        live = false;
        winner = firstPlace().player;
    }

    function returnPlayer(address _player) public view returns(address player_, uint256 clicks_, uint256 cooldown_) {
        Player memory player = allPlayers[numberByAddress[_player]];
        return (player.player, player.clicks, player.cooldown);
    }

    function gameEndTime() public view returns(uint256) {
        if (block.timestamp - startTimestamp <= oneWeek) {
            return oneWeek - (block.timestamp - startTimestamp);
        }
        return 0;
    }

    function coolDownByPlayer(address player) public view returns(uint256) {
        if (block.timestamp - allPlayers[numberByAddress[player]].cooldown >= oneMinute) {
            return 0;
        }
        return oneMinute - (block.timestamp - allPlayers[numberByAddress[player]].cooldown);
    }

    function click() public {
        require(live, "game not live");
        require(block.timestamp - startTimestamp <= oneWeek, "game over");
        require(block.timestamp - allPlayers[numberByAddress[msg.sender]].cooldown >= oneMinute, "too fast");
        if (!activePlayer[msg.sender]) {
            activePlayer[msg.sender] = true;
            players++;
            playerByNumber[players] = msg.sender;
            numberByAddress[msg.sender] = players;
            allPlayers[players].player = msg.sender;
        }
        allPlayers[numberByAddress[msg.sender]].cooldown = block.timestamp;
        allPlayers[numberByAddress[msg.sender]].clicks++;
        emit Click(msg.sender, allPlayers[numberByAddress[msg.sender]].clicks);
    }

    function getPlayers() public view returns(Player[] memory) {
        uint totalPlayers = 0;
        Player[] memory player = new Player[](players);

        for (uint i = 1; i <= players; i++) {
            Player memory p = allPlayers[i];
            player[totalPlayers] = p;
            totalPlayers++;
        }
        return player;
    }

    function sortByClicks() public view returns(Player[] memory) {
        Player[] memory player = getPlayers();

        for (uint i = 1; i < player.length; i++) {
            for (uint j = 0; j < i; j++) {
                if (player[i].clicks > player[j].clicks) {
                    Player memory p = player[i];
                    player[i] = player[j];
                    player[j] = p;
                }
            }
        }
        return player;
    }

    function firstPlace() public view returns (Player memory) {
        Player[] memory player = sortByClicks();
        return player[0];
    }

    function mintNFT() public payable {
        require(winner != address(0), "no winner");
        require(winner == msg.sender, "not winner");
        require(mints < 3, "minted 3 nfts already");
        require(!live, "game must end");
        mints++;
        NFT(nft).mint(1);
        uint256 id = NFT(nft).tokensByOwner(address(this))[0];
        NFT(nft).safeTransferFrom(address(this), msg.sender, id);
        emit Mint(msg.sender, mints);
    }

    function withdrawWinnings() public {
        require(winner != address(0), "no winner");
        require(winner == msg.sender, "not winner");
        require(!live, "game must end");
        require(!withdrew, "already withdrew");
        withdrew = true;
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
        emit Withdraw(msg.sender, balance);
    }

    function emergencyEnd() public onlyOwner {
        live = false;
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance); 
    }

}