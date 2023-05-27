// SPDX-License-Identifier: MIT

// Project: NERD Token
//
// Website: http://nerd.vip
// Twitter: @nerdoneth
//
// Note: The coin is completely useless and intended solely for entertainment and educational purposes. Please do not expect any financial returns.

pragma solidity ^0.8.20;

import "./INerd.sol";
import "./IWETH.sol";
import "./IUniswapV2Pair.sol";
import "./IERC20.sol";
import "./ERC20.sol";
import "./NerdSR.sol";

contract Nerd is ERC20, INerd {
    uint256 private constant YEAR_IN_SECONDS = 365 days;
    uint256 private constant MAX_STAKING_RATE = 25_600;
    uint256 private constant RATE_TICK = 64 days / MAX_STAKING_RATE;

    uint40 private constant AUCTION_DEFAULT_DURATION = 12 hours;
    // Amount of seconds auction will be extended to in case of new bid
    uint256 private constant AUCTION_EXTEND_SECONDS = 20 minutes;

    IWETH private constant WETH = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    NerdSR private immutable nerdSR;

    struct StakeEntry {
        uint128 amount;
        uint40 start;
    }

    mapping(address => StakeEntry) public stakes;
    uint256 public totalStaked;

    struct AuctionState {
        address winner;
        uint128 bidAmount;
        uint40 deadline;
    }

    AuctionState public auction;
    uint256 public auctionPoolAmount;

    struct AuctionWinner {
        uint128 bidAmount;
        uint128 mintAmount;
        address winner;
    }

    AuctionWinner public previousAuction;

    // Main Uniswap pair - NERD/WETH
    address public immutable mainPool;

    constructor(address deployer) ERC20("Nerd", "NERD") {
        nerdSR = new NerdSR();

        (address token0, address token1) =
            address(this) < address(WETH) ? (address(this), address(WETH)) : (address(WETH), address(this));

        // locally precalculate address of main pool to make it immutable - this pair doesn't exist yet
        mainPool = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            address(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f),
                            keccak256(abi.encodePacked(token0, token1)),
                            hex"96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f"
                        )
                    )
                )
            )
        );

        // Total supply: 64M
        // 6.4M - NERD/NERDs Uniswap pool
        _mint(msg.sender, 6_400_000 ether);
        // 10k - NERD/ETH Uniswap pool - prefill/ LP minted in factory
        _mint(mainPool, 10_000 ether);
        // 6.4M - deployer, without Sale Rights
        _mint(deployer, 6_400_000 ether);
        // remaining 51.190 M - available for airdrop
        _mint(address(this), 51_190_000 ether);

        // 25,6M NERDs - NERD/NERDs Uniswap pool
        nerdSR.mint(msg.sender, 25_600_000 ether);

        unchecked {
            auction = AuctionState(address(0), uint128(1), uint40(block.timestamp) + AUCTION_DEFAULT_DURATION);
        }
    }

    function airdrop() external payable override {
        uint256 fromBalance = balanceOf(address(this));

        uint256 reward;
        unchecked {
            reward = msg.value * 10_000;
        }

        // in theory can overflow but would require very high msg.value (for example evm bug)
        require(fromBalance >= totalStaked + reward);

        unchecked {
            _balances[address(this)] = fromBalance - reward;
            _balances[msg.sender] += reward;
        }

        emit Transfer(address(this), msg.sender, reward);
    }

    function stake(uint256 amount) external override {
        StakeEntry storage entry = stakes[msg.sender];
        _withdrawStakingReward(entry);

        if (amount != 0) {
            _transfer(msg.sender, address(this), amount);
            unchecked {
                entry.amount += uint128(amount);
                totalStaked += amount;
            }
        }
    }

    function unstake(uint256 amount) external override {
        StakeEntry storage entry = stakes[msg.sender];
        _withdrawStakingReward(entry);

        if (amount != 0) {
            require(amount <= entry.amount);
            _transfer(address(this), msg.sender, amount);
            unchecked {
                entry.amount -= uint128(amount);
                totalStaked -= amount;
            }
        }
    }

    function stakeRewardOf(address owner) external view override returns (uint256 amount) {
        StakeEntry memory entry = stakes[owner];
        return _stakeReward(entry);
    }

    function bid(uint256 amount, uint256 deadline) external override {
        require(deadline >= block.timestamp);

        _burn(msg.sender, amount);
        unchecked {
            AuctionState memory _auction = auction;
            if (block.timestamp > _auction.deadline) {
                // new auction
                require(amount > 0);

                // Airdrop SR (10% of auction pool)
                uint256 _auctionPoolAmount = auctionPoolAmount;
                uint256 mintAmount = _auctionPoolAmount / 10;
                auctionPoolAmount = _auctionPoolAmount - mintAmount;
                nerdSR.mint(_auction.winner, mintAmount);

                // Aridrop 0.05% of LP
                uint256 lpAmount = IERC20(mainPool).balanceOf(address(this)) / 2000;
                if (lpAmount != 0) IERC20(mainPool).transfer(_auction.winner, lpAmount);

                previousAuction = AuctionWinner(_auction.bidAmount, 0, _auction.winner);
                auction = AuctionState(msg.sender, uint128(amount), uint40(block.timestamp + AUCTION_DEFAULT_DURATION));
            } else {
                // new top bid
                require(amount > ((uint256(_auction.bidAmount) / 100) * 101)); // 101%

                _mint(_auction.winner, _auction.bidAmount);

                // will not underflow as we know that: (block.timestamp <= _auction.deadline)
                uint40 newDeadline = (_auction.deadline - block.timestamp < AUCTION_EXTEND_SECONDS)
                    ? uint40(block.timestamp + AUCTION_EXTEND_SECONDS)
                    : _auction.deadline;

                auction = AuctionState(msg.sender, uint128(amount), newDeadline);
            }
        }
    }

    function winnerAddLiquidity() external override {
        require(msg.sender == previousAuction.winner);
        unchecked {
            // Limit execution of this function to one per auction
            require(++previousAuction.mintAmount == 1);
        }

        if (address(this).balance != 0) {
            WETH.deposit{value: address(this).balance}();
        }

        uint256 ethAmount = IERC20(address(WETH)).balanceOf(address(this));
        require(ethAmount > 1_000_000 gwei);
        if (ethAmount > 100 ether) {
            ethAmount = 100 ether;
        }

        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = IUniswapV2Pair(mainPool).getReserves();
        require(blockTimestampLast != block.timestamp);
        (uint256 nerdReserve, uint256 wethReserve) =
            address(this) < address(WETH) ? (reserve0, reserve1) : (reserve1, reserve0);

        uint256 nerdAmount = (nerdReserve * ethAmount) / wethReserve;
        _mint(mainPool, nerdAmount);
        IERC20(address(WETH)).transfer(mainPool, ethAmount);
        IUniswapV2Pair(mainPool).mint(address(this));
    }

    function winnerMintSR(uint256 amount) external override {
        _spendWinnerMintAmount(amount);

        uint256 nerdAmount;
        unchecked {
            nerdAmount = (amount / 10) + 1;
        }

        _burn(msg.sender, nerdAmount);
        nerdSR.mint(msg.sender, amount);
    }

    function winnerBurnSR(uint256 amount) external override {
        _spendWinnerMintAmount(amount);
        _burnSR(amount, 10);
    }

    function burnSR(uint256 amount) external override {
        _burnSR(amount, 40);
    }

    function _burnSR(uint256 amount, uint256 rate) internal {
        uint256 nerdAmount;
        unchecked {
            nerdAmount = amount / rate;
        }

        nerdSR.burn(msg.sender, amount);
        _mint(msg.sender, nerdAmount);
    }

    // `amount` range have to be asserted before to avoid overflow
    function _spendWinnerMintAmount(uint256 amount) internal {
        require(msg.sender == previousAuction.winner);

        unchecked {
            // This can overflow, assumption is that calling function already asserte range of `amount` for it to not happen.
            uint256 afterAmount = uint256(previousAuction.mintAmount) + amount;
            require(afterAmount <= uint256(previousAuction.bidAmount));
            previousAuction.mintAmount = uint128(afterAmount);
        }
    }

    function _withdrawStakingReward(StakeEntry storage stakeEntry) internal {
        if (stakeEntry.amount != 0) {
            uint256 rewardAmount = _stakeReward(stakeEntry);
            if (rewardAmount > 0) {
                nerdSR.mint(msg.sender, rewardAmount);
            }
        }

        stakeEntry.start = uint40(block.timestamp);
    }

    function _stakeReward(StakeEntry memory stakeEntry) internal view returns (uint256 amount) {
        unchecked {
            uint256 period = block.timestamp - stakeEntry.start;

            uint256 rate = period / RATE_TICK;
            if (rate > MAX_STAKING_RATE) {
                rate = MAX_STAKING_RATE;
            }

            return (((rate * stakeEntry.amount) / YEAR_IN_SECONDS) * period) / 10_000;
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        if (from == mainPool) {
            // airdrop SR when transfering out of main pool
            uint256 srAmount;
            unchecked {
                srAmount = amount / 2;
                auctionPoolAmount += srAmount;
            }
            nerdSR.mint(to, srAmount);
        } else if (to == mainPool) {
            // burn SR when transfering to pool
            nerdSR.burn(from, amount);
        }
    }

    function SR() external view virtual override returns (address) {
        return address(nerdSR);
    }
}