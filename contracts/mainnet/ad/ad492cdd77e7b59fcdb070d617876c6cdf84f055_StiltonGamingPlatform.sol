/**
 *Submitted for verification at Etherscan.io on 2022-05-05
*/

// File: contracts/IERC721.sol

pragma solidity ^0.8.7;

interface IERC721 {
    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256);
}

// File: contracts/IERC20.sol

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}
// File: contracts/Ownable.sol

abstract contract Ownable {
    address _owner;

    modifier onlyOwner() {
        require(msg.sender == _owner);
        _;
    }

    constructor() {
        _owner = msg.sender;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        _owner = newOwner;
    }
}

// File: contracts/StiltonGamingPlatform.sol

//import "hardhat/console.sol";




struct BalanceChange {
    address account;
    int256 change;
}

contract StiltonGamingPlatform is Ownable {
    IERC20 public erc20;
    IERC721 public nft;
    address public caasbank;
    bool public enabled;
    mapping(address => uint256) erc20Balances;
    mapping(address => bool) public admins;
    uint256 public balanceTotal;

    event Jackpot(address indexed account, uint256 count, uint256 nftId);

    modifier onlyAdmin() {
        require(admins[msg.sender], "only for admin");
        _;
    }

    constructor(address erc20Address, address nftAddress) {
        erc20 = IERC20(erc20Address);
        nft = IERC721(nftAddress);
    }

    function SetEnable(bool newEnabled) external onlyOwner {
        enabled = newEnabled;
    }

    function topUpBalance(uint256 count) external {
        require(enabled, "not enabled");
        erc20.transferFrom(msg.sender, address(this), count);
        addBalanceInternal(msg.sender, count);
    }

    function topUpJackpot(uint256 count) external {
        erc20.transferFrom(msg.sender, address(this), count);
        uint256 addingBalance = count - count / 10; // adds 10% to cover fee
        addBalanceInternal(address(0), addingBalance);
    }

    function AddToJackpot(uint256 count) external {
        erc20.transferFrom(msg.sender, address(this), count);
        addBalanceInternal(address(0), count);
    }

    function setAdmin(address account, bool isAdmin) public onlyOwner {
        admins[account] = isAdmin;
    }

    function setCaasbank(address caasbankAddress) external onlyOwner {
        caasbank = caasbankAddress;
    }

    function setErc20(address erc20Address) external onlyOwner {
        erc20 = IERC20(erc20Address);
    }

    function setNft(address nftAddress) external onlyOwner {
        nft = IERC721(nftAddress);
    }

    function removeCaasbank() external onlyOwner {
        caasbank = address(0);
    }

    function jackpot() public view returns (uint256) {
        return (balanceOf(address(0)) * 6) / 10;
    }

    function giveJackpot(address account, uint256 bid) external onlyAdmin {
        require(enabled, "not enabled");
        // give erc20
        uint256 count = bid * 50;
        uint256 jp = jackpot();
        if (count > jp) count = jp;
        subBalanceInternal(address(0), count);
        addBalance(account, count);

        // give nft
        uint256 nftId;
        uint256 nftBalance = nft.balanceOf(address(this));
        if (nftBalance > 0) {
            nftId = nft.tokenOfOwnerByIndex(address(this), 0);
            nft.safeTransferFrom(address(this), account, nftId);
        }

        // event
        emit Jackpot(account, count, nftId);
    }

    function withdrawJackpot(address account, uint256 count)
        external
        onlyAdmin
    {
        require(erc20Balances[address(0)] >= count, "not enough jackpot");
        erc20.transfer(account, count);
        subBalanceInternal(address(0), count);
    }

    function addBalance(address account, uint256 count) public onlyAdmin {
        addBalanceInternal(account, count);
    }

    function addBalanceInternal(address account, uint256 count) internal {
        erc20Balances[account] += count;
        balanceTotal += count;
    }

    function subBalance(address account, uint256 count) public onlyAdmin {
        subBalanceInternal(account, count);
    }

    function subBalanceInternal(address account, uint256 count) internal {
        erc20Balances[account] -= count;
        balanceTotal -= count;
    }

    function applyChanges(BalanceChange[] calldata changes) external onlyAdmin {
        require(enabled, "not enabled");
        for (uint256 i = 0; i < changes.length; ++i) {
            int256 change = changes[i].change;
            if (change > 0)
                addBalanceInternal(changes[i].account, uint256(change));
            else subBalanceInternal(changes[i].account, uint256(-change));
        }
    }

    function withdrawErc20(address account, uint256 count) external onlyAdmin {
        require(enabled, "not enabled");
        require(balanceOf(account) >= count, "not enough balance");

        uint256 jp = (count * 25) / 1000;
        uint256 caas = (count * 25) / 1000;
        if (caasbank == address(0)) caas = 0;
        uint256 user = count - caas - jp;

        if (caas > 0) erc20.transfer(caasbank, caas);
        erc20.transfer(account, user);
        addBalanceInternal(address(0), jp);

        erc20Balances[account] -= caas + user + jp;
        balanceTotal -= caas + user;
    }

    function withdrawNft(address account, uint256 id) public onlyAdmin {
        nft.safeTransferFrom(address(this), account, id);
    }

    function withdrawNft(address account) external onlyOwner {
        uint256 nftBalance = nft.balanceOf(address(this));
        require(nftBalance > 0, "has no nft");
        nft.safeTransferFrom(
            address(this),
            account,
            nft.tokenOfOwnerByIndex(address(this), 0)
        );
    }

    function withdrawErc20Owner() external onlyOwner {
        uint256 balance = erc20.balanceOf(address(this));
        require(balance > 0);
        erc20.transfer(msg.sender, balance);
    }

    function withdrawNftOwner() external onlyOwner {
        uint256 balance = nft.balanceOf(address(this));
        require(balance > 0);
        while (balance > 0) {
            nft.safeTransferFrom(
                address(this),
                msg.sender,
                nft.tokenOfOwnerByIndex(address(this), 0)
            );
            --balance;
        }
    }

    function balanceOf(address account) public view returns (uint256) {
        return erc20Balances[account];
    }

    function withdrawEth() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}