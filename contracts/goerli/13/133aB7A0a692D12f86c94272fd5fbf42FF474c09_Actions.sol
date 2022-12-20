/**
 *Submitted for verification at Etherscan.io on 2022-12-20
*/

// actions.sol -- Tinlake actions
// Copyright (C) 2020 Centrifuge

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity ^0.8.1;

interface NFTLike {
    function approve(address usr, uint256 token) external;
    function transferFrom(address src, address dst, uint256 token) external;
    function mintTo(address usr) external returns (uint256);
}

interface ERC20Like {
    function approve(address usr, uint256 amount) external;
    function transfer(address dst, uint256 amount) external;
    function transferFrom(address src, address dst, uint256 amount) external;
}

interface ShelfLike {
    function pile() external returns (address);
    function lock(uint256 loan) external;
    function unlock(uint256 loan) external;
    function issue(address registry, uint256 token) external returns (uint256 loan);
    function close(uint256 loan) external;
    function borrow(uint256 loan, uint256 amount) external;
    function withdraw(uint256 loan, uint256 amount, address usr) external;
    function repay(uint256 loan, uint256 amount) external;
    function shelf(uint256 loan)
        external
        returns (address registry, uint256 tokenId, uint256 price, uint256 principal, uint256 initial);
}

interface PileLike {
    function debt(uint256 loan) external returns (uint256);
}

interface RootLike {
    function borrowerDeployer() external view returns (address);
}

interface BorrowerDeployerLike {
    function shelf() external view returns (address);
    function feed() external view returns (address);
}

interface FeedLike {
    function update(bytes32 lookupId, uint256 value, uint256 riskGroup) external;
}

contract Actions {
    // --- Events ---
    event Issue(address indexed shelf, address indexed registry, uint256 indexed token);
    event Transfer(address indexed registry, uint256 indexed token);
    event Lock(address indexed shelf, uint256 indexed loan);
    event BorrowWithdraw(address indexed shelf, uint256 indexed loan, uint256 amount, address indexed usr);
    event Repay(address indexed shelf, address indexed erc20, uint256 indexed loan, uint256 amount);
    event Unlock(address indexed shelf, address indexed registry, uint256 token, uint256 indexed loan);
    event Close(address indexed shelf, uint256 indexed loan);
    event ApproveNFT(address indexed registry, address indexed usr, uint256 tokenAmount);
    event ApproveERC20(address indexed erc20, address indexed usr, uint256 amount);
    event TransferERC20(address indexed erc20, address indexed dst, uint256 amount);
    event Minted(address indexed registry, uint256 tokenId);

    address public immutable shelf;
    address public immutable pile;
    address public immutable feed;
    address public immutable self;

    // address to deposit withdraws
    address public immutable withdrawAddress;

    // modifier only delegated call
    modifier onlyDelegateCall() {
        require(address(this) != self, "only-delegate-call");
        _;
    }

    constructor(address root_, address withdrawAddress_) {
        address shelf_ = BorrowerDeployerLike(RootLike(root_).borrowerDeployer()).shelf();
        address pile_ = ShelfLike(shelf_).pile();
        address feed_ = BorrowerDeployerLike(RootLike(root_).borrowerDeployer()).feed();
        address self_ = address(this);
        require(withdrawAddress_ != address(0), "withdraw-address-not-set");
        require(shelf_ != address(0), "shelf-not-set");
        require(pile_ != address(0), "pile-not-set");
        require(feed_ != address(0), "feed-not-set");
        withdrawAddress = withdrawAddress_;
        shelf = shelf_;
        self = self_;
        pile = pile_;
        feed = feed_;
    }

    function mintAsset(address minter) public onlyDelegateCall returns (uint256 tokenId) {
        tokenId = NFTLike(minter).mintTo(address(this));
        emit Minted(minter, tokenId);
    }

    // --- Borrower Actions ---
    function issue(address shelf_, address registry, uint256 token) public onlyDelegateCall returns (uint256 loan) {
        require(shelf == shelf_, "invalid-shelf");
        loan = ShelfLike(shelf_).issue(registry, token);
        // proxy approve shelf to take nft
        NFTLike(registry).approve(shelf_, token);

        emit Issue(shelf_, registry, token);
        return loan;
    }

    function transfer(address registry, uint256 token) public onlyDelegateCall {
        // transfer nft from borrower to proxy
        NFTLike(registry).transferFrom(msg.sender, address(this), token);
        emit Transfer(registry, token);
    }

    function lock(address shelf_, uint256 loan) public onlyDelegateCall {
        require(shelf == shelf_, "invalid-shelf");
        ShelfLike(shelf_).lock(loan);
        emit Lock(shelf_, loan);
    }

    function borrowWithdraw(address shelf_, uint256 loan, uint256 amount, address usr) public onlyDelegateCall {
        require(shelf == shelf_, "invalid-shelf");
        require(usr == withdrawAddress, "invalid-user");
        ShelfLike(shelf_).borrow(loan, amount);
        ShelfLike(shelf_).withdraw(loan, amount, withdrawAddress);
        emit BorrowWithdraw(shelf_, loan, amount, withdrawAddress);
    }

    function repay(address shelf_, address erc20, uint256 loan, uint256 amount) public onlyDelegateCall {
        require(shelf == shelf_, "invalid-shelf");
        // don't allow repaying more than the debt as currency would get stuck in the proxy
        uint256 debt = PileLike(ShelfLike(shelf_).pile()).debt(loan);
        if (amount > debt) {
            amount = debt;
        }

        _repay(erc20, loan, amount);
    }

    function repayFullDebt(address shelf_, address pile_, address erc20, uint256 loan) public onlyDelegateCall {
        require(shelf == shelf_, "invalid-shelf");
        require(pile == pile_, "invalid-pile");
        _repay(erc20, loan, PileLike(pile_).debt(loan));
    }

    function _repay(address erc20, uint256 loan, uint256 amount) internal {
        // transfer money from borrower to proxy
        ERC20Like(erc20).transferFrom(msg.sender, address(this), amount);
        ERC20Like(erc20).approve(address(shelf), amount);
        ShelfLike(shelf).repay(loan, amount);
        emit Repay(shelf, erc20, loan, amount);
    }

    function unlock(address shelf_, address registry, uint256 token, uint256 loan) public onlyDelegateCall {
        require(shelf == shelf_, "invalid-shelf");
        ShelfLike(shelf_).unlock(loan);
        NFTLike(registry).transferFrom(address(this), msg.sender, token);
        emit Unlock(shelf_, registry, token, loan);
    }

    function close(address shelf_, uint256 loan) public onlyDelegateCall {
        require(shelf == shelf_, "invalid-shelf");
        ShelfLike(shelf_).close(loan);
        emit Close(shelf_, loan);
    }

    // --- Borrower Wrappers ---
    function transferIssue(address shelf_, address registry, uint256 token)
        public
        onlyDelegateCall
        returns (uint256 loan)
    {
        require(shelf == shelf_, "invalid-shelf");
        transfer(registry, token);
        return issue(shelf_, registry, token);
    }

    function lockBorrowWithdraw(address shelf_, uint256 loan, uint256 amount, address usr) public onlyDelegateCall {
        require(shelf == shelf_, "invalid-shelf");
        require(usr == withdrawAddress, "invalid-user");
        lock(shelf_, loan);
        borrowWithdraw(shelf_, loan, amount, withdrawAddress);
    }

    function mintIssuePriceLock(address minter, address registry, uint256 price, uint256 riskGroup)
        public
        onlyDelegateCall
        returns (uint256 loan, uint256 tokenId)
    {
        tokenId = mintAsset(minter);
        loan = issue(shelf, registry, tokenId);
        NFTLike(registry).approve(shelf, tokenId);
        lock(shelf, loan);
        bytes32 lookupId = keccak256(abi.encodePacked(address(registry), tokenId));
        FeedLike(feed).update(lookupId, price, riskGroup);
    }

    function transferIssueLockBorrowWithdraw(
        address shelf_,
        address registry,
        uint256 token,
        uint256 amount,
        address usr
    ) public onlyDelegateCall {
        require(shelf == shelf_, "invalid-shelf");
        require(usr == withdrawAddress, "invalid-user");
        uint256 loan = transferIssue(shelf_, registry, token);
        lockBorrowWithdraw(shelf_, loan, amount, usr);
    }

    function repayUnlockClose(
        address shelf_,
        address pile_,
        address registry,
        uint256 token,
        address erc20,
        uint256 loan
    ) public onlyDelegateCall {
        require(shelf == shelf_, "invalid-shelf");
        require(pile == pile_, "invalid-pile");
        repayFullDebt(shelf_, pile_, erc20, loan);
        unlock(shelf_, registry, token, loan);
        close(shelf_, loan);
    }
}