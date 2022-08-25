// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interface/INFTSwap.sol";
import "./interface/IERC20.sol";
import "./interface/IERC721.sol";
import "./interface/IERC1155.sol";

contract NFTSwapF is INFTSwap, Ownable {
    SwapBoxConfig private swapConfig;
    address[] public whitelistERC20Tokens;
    address[] public whitelistERC721Tokens;
    address[] public whitelistERC1155Tokens;

    constructor() {
        swapConfig.usingERC721WhiteList = true;
        swapConfig.usingERC1155WhiteList = true;
        swapConfig.NFTTokenCount = 5;
        swapConfig.ERC20TokenCount = 5;
    }

    function _returnAssetsHelper(
        ERC721Details[] memory erc721Details,
        ERC20Details memory erc20Details,
        ERC1155Details[] memory erc1155Details,
        uint256 gasTokenAmount,
        address from,
        address to
    ) external {
        for (uint256 i = 0; i < erc721Details.length; i++) {
            for (uint256 j = 0; j < erc721Details[i].ids.length; j++) {
                IERC721(erc721Details[i].tokenAddr).transferFrom(
                    address(this),
                    to,
                    erc721Details[i].ids[j]
                );
            }
        }

        for (uint256 i = 0; i < erc20Details.tokenAddrs.length; i++) {
            IERC20(erc20Details.tokenAddrs[i]).transfer(
                address(this),
                erc20Details.amounts[i]
            );
        }

        for (uint256 i = 0; i < erc1155Details.length; i++) {
            IERC1155(erc1155Details[i].tokenAddr).safeBatchTransferFrom(
                from,
                address(this),
                erc1155Details[i].ids,
                erc1155Details[i].amounts,
                ""
            );
        }

        if (gasTokenAmount > 0) {
            payable(to).transfer(gasTokenAmount);
        }
    }

    function _checkAssets(
        ERC721Details[] memory erc721Details,
        ERC20Details memory erc20Details,
        ERC1155Details[] memory erc1155Details,
        address offer
    ) external view {
        require(
            (erc721Details.length + erc1155Details.length) <=
                swapConfig.NFTTokenCount,
            "Too much NFTs selected"
        );

        for (uint256 i = 0; i < erc721Details.length; i++) {
            require(
                validateWhiteListERC721Token(erc721Details[i].tokenAddr),
                "Not Allowed ERC721 Token"
            );
            require(
                erc721Details[i].ids.length > 0,
                "Non included ERC721 token"
            );

            for (uint256 j = 0; j < erc721Details[i].ids.length; j++) {
                require(
                    IERC721(erc721Details[i].tokenAddr).getApproved(
                        erc721Details[i].ids[j]
                    ) == address(this),
                    "ERC721 tokens must be approved to swap contract"
                );
            }
        }

        // check duplicated token address
        require(
            erc20Details.tokenAddrs.length <= swapConfig.ERC20TokenCount,
            "Too much ERC20 tokens selected"
        );
        for (uint256 i = 0; i < erc20Details.tokenAddrs.length; i++) {
            uint256 tokenCount = 0;
            for (uint256 j = 0; j < erc20Details.tokenAddrs.length; j++) {
                if (erc20Details.tokenAddrs[i] == erc20Details.tokenAddrs[j]) {
                    tokenCount++;
                }
            }

            require(tokenCount == 1, "Invalid ERC20 tokens");
        }

        for (uint256 i = 0; i < erc20Details.tokenAddrs.length; i++) {
            require(
                validateWhiteListERC20Token(erc20Details.tokenAddrs[i]),
                "Not Allowed ERC20 Tokens"
            );
            require(
                IERC20(erc20Details.tokenAddrs[i]).allowance(
                    offer,
                    address(this)
                ) >= erc20Details.amounts[i],
                "ERC20 tokens must be approved to swap contract"
            );
            require(
                IERC20(erc20Details.tokenAddrs[i]).balanceOf(offer) >=
                    erc20Details.amounts[i],
                "Insufficient ERC20 tokens"
            );
        }

        for (uint256 i = 0; i < erc1155Details.length; i++) {
            require(
                validateWhiteListERC1155Token(erc1155Details[i].tokenAddr),
                "Not Allowed ERC721 Token"
            );
            for (uint256 j = 0; j < erc1155Details[i].ids.length; i++) {
                require(
                    IERC1155(erc1155Details[i].tokenAddr).balanceOf(
                        offer,
                        erc1155Details[i].ids[j]
                    ) > 0,
                    "This token not exist"
                );
                require(
                    IERC1155(erc1155Details[i].tokenAddr).isApprovedForAll(
                        offer,
                        address(this)
                    ),
                    "ERC1155 token must be approved to swap contract"
                );
            }
        }
    }

    function _transferAssetsHelper(
        ERC721Details[] memory erc721Details,
        ERC20Details memory erc20Details,
        ERC1155Details[] memory erc1155Details,
        address from
    ) external {
        for (uint256 i = 0; i < erc721Details.length; i++) {
            for (uint256 j = 0; j < erc721Details[i].ids.length; j++) {
                IERC721(erc721Details[i].tokenAddr).transferFrom(
                    from,
                    address(this),
                    erc721Details[i].ids[j]
                );
            }
        }

        for (uint256 i = 0; i < erc20Details.tokenAddrs.length; i++) {
            IERC20(erc20Details.tokenAddrs[i]).transferFrom(
                from,
                address(this),
                erc20Details.amounts[i]
            );
        }

        for (uint256 i = 0; i < erc1155Details.length; i++) {
            IERC1155(erc1155Details[i].tokenAddr).safeBatchTransferFrom(
                from,
                address(this),
                erc1155Details[i].ids,
                erc1155Details[i].amounts,
                ""
            );
        }
    }
    
    function addWhiteListToken(address erc20Token) external onlyOwner {
        require(
            validateWhiteListERC20Token(erc20Token) == false,
            "Exist Token"
        );
        whitelistERC20Tokens.push(erc20Token);
    }

    function setUsingERC721Whitelist(bool usingList) external onlyOwner {
        swapConfig.usingERC721WhiteList = usingList;
    }

    function setUsingERC1155Whitelist(bool usingList) external onlyOwner {
        swapConfig.usingERC1155WhiteList = usingList;
    }

    function getERC20WhiteListTokens() public view returns (address[] memory) {
        return whitelistERC20Tokens;
    }

    function removeFromERC20WhiteList(uint256 index) external onlyOwner {
        require(index < whitelistERC20Tokens.length, "Invalid element");
        whitelistERC20Tokens[index] = whitelistERC20Tokens[
            whitelistERC20Tokens.length - 1
        ];
        whitelistERC20Tokens.pop();
    }

    function addWhiliteListERC721Token(address erc721Token) external onlyOwner {
        require(
            validateWhiteListERC721Token(erc721Token) == false,
            "Exist Token"
        );
        whitelistERC721Tokens.push(erc721Token);
    }

    function getERC721WhiteListTokens() public view returns (address[] memory) {
        return whitelistERC721Tokens;
    }

    function removeFromERC721WhiteList(uint256 index) external onlyOwner {
        require(index < whitelistERC721Tokens.length, "Invalid element");
        whitelistERC721Tokens[index] = whitelistERC721Tokens[
            whitelistERC721Tokens.length - 1
        ];
        whitelistERC721Tokens.pop();
    }

    function addWhiliteListERC1155Token(address erc1155Token)
        external
        onlyOwner
    {
        require(
            validateWhiteListERC1155Token(erc1155Token) == false,
            "Exist Token"
        );
        whitelistERC1155Tokens.push(erc1155Token);
    }

    function getERC1155WhiteListTokens()
        public
        view
        returns (address[] memory)
    {
        return whitelistERC1155Tokens;
    }

    function removeFromERC1155WhiteList(uint256 index) external onlyOwner {
        require(index < whitelistERC1155Tokens.length, "Invalid element");
        whitelistERC1155Tokens[index] = whitelistERC1155Tokens[
            whitelistERC1155Tokens.length - 1
        ];
        whitelistERC1155Tokens.pop();
    }

    // Checking whitelist ERC20 Token
    function validateWhiteListERC20Token(address erc20Token)
        public
        view
        returns (bool)
    {
        for (uint256 i = 0; i < whitelistERC20Tokens.length; i++) {
            if (whitelistERC20Tokens[i] == erc20Token) {
                return true;
            }
        }

        return false;
    }

    // Checking whitelist ERC721 Token
    function validateWhiteListERC721Token(address erc721Token)
        public
        view
        returns (bool)
    {
        if (!swapConfig.usingERC721WhiteList) return true;

        for (uint256 i = 0; i < whitelistERC721Tokens.length; i++) {
            if (whitelistERC721Tokens[i] == erc721Token) {
                return true;
            }
        }

        return false;
    }

    function validateWhiteListERC1155Token(address erc1155Token)
        public
        view
        returns (bool)
    {
        if (!swapConfig.usingERC1155WhiteList) return true;

        for (uint256 i = 0; i < whitelistERC721Tokens.length; i++) {
            if (whitelistERC1155Tokens[i] == erc1155Token) {
                return true;
            }
        }

        return false;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface INFTSwap {

    event SwapBoxState (
        uint256 swapItemID,
        address owner,
        State state,
        uint256 createdTime,
        uint256 updateTime,
        uint256 gasTokenAmount,
        ERC721Details[] erc721Tokens,
        ERC20Details erc20Tokens,
        ERC1155Details[] erc1155Tokens
    );

     event SwapBoxOffer(
        uint256 listSwapBoxID,
        uint256 offerSwapBoxID
    );

    event SwapBoxWithDrawOffer(
        uint256 listSwapBoxID,
        uint256 offerSwapBoxID
    );

    event SwapBoxDeList(
        uint256 listSwapBoxID,
        State state,
        BoxOffer[] offers
    );

    event SwapBoxDeOffer(
        uint256 offerSwapBoxID,
        State state,
        BoxOffer[] offers
    );

    event Swaped (
        uint256 listID,
        address listOwner,
        uint256 offerID,
        address offerOwner
    );

    struct ERC20Details {
        address[] tokenAddrs;
        uint256[] amounts;
    }
    struct ERC721Details {
        address tokenAddr;
        uint256[] ids;
    }
    struct ERC1155Details {
        address tokenAddr;
        uint256[] ids;
        uint256[] amounts;
    }

    struct BoxOffer {
        uint256 boxID;
        bool active;
    }
    struct SwapBox {
        uint256 id;
        address owner;
        ERC721Details[] erc721Tokens;
        ERC20Details erc20Tokens;
        ERC1155Details[] erc1155Tokens;
        uint256 gasTokenAmount;
        uint256 createdTime;
        State state;
        BoxOffer[] offers;
    }

    struct SwapBoxConfig {
        bool usingERC721WhiteList;
        bool usingERC1155WhiteList;
        uint256 NFTTokenCount;
        uint256 ERC20TokenCount;
    }

    enum State {
        Initiated,
        Waiting_for_offers,
        Offered,
        Destroyed
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;
interface IERC721{
    function balanceOf(address owner) external view returns (uint256 balance);
    function safeTransferFrom(address from,address to,uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function safeTransferFrom(address from,address to,uint256 tokenId,bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
interface IERC1155 {
    function balanceOf(address account, uint256 id) external view returns (uint256);
    function isApprovedForAll(address account, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) external;
    function safeBatchTransferFrom(address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}