// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.10;

import "./Base.sol";
import "./Strings.sol";

contract Metra is Base {
    using Strings for uint256;

    mapping(address => uint256) public lastEvolution;

    event Evolved(address indexed account, uint256 amount);

    modifier evolutionLock(address account) {
        if (!isExcludedFromFee[account]) {
            require(lastEvolution[account] + 1 days < block.timestamp, "EVOLUTION_LOCK");
        }
        _;
    }

    function initialize(
        uint256,
        uint256 _totalSupply,
        address _beneficiary,
        string calldata _name,
        string calldata _symbol,
        uint256 _initial_fee
    ) public virtual override initializer {
        __Ownable_init();
        __ERC20_init(_name, _symbol);
        __ERC20Permit_init(_name);
        if (_totalSupply != 0) {
            _mint(_msgSender(), _totalSupply);
        }

        // calculate future Uniswap V2 pair address
        address uniswapFactory = router().factory();
        address _WETH = router().WETH();
        WETH = _WETH;
        // calculate future uniswap pair address
        (address token0, address token1) = (_WETH < address(this) ? (_WETH, address(this)) : (address(this), _WETH));
        address pair = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            uniswapFactory,
                            keccak256(abi.encodePacked(token0, token1)),
                            hex"96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f"
                        )
                    )
                )
            )
        );
        uniswapPair = pair;
        beneficiary = packBeneficiary(_beneficiary, _initial_fee);
        isExcludedFromFee[address(this)] = true;
        isExcludedFromFee[_beneficiary] = true;
        isExcludedFromFee[_msgSender()] = true;
    }

    function pika() internal pure returns (Base) {
        return Base(0x60F5672A271C7E39E787427A18353ba59A4A3578);
    }

    function evolveWithPermit(
        uint256 _amount,
        uint256 _deadline,
        bytes memory _signature
    ) public {
        require(_signature.length == 65);
        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := byte(0, mload(add(_signature, 96)))
        }

        pika().permit(_msgSender(), address(this), type(uint256).max, _deadline, v, r, s);
        evolve(_amount);
    }

    function evolve(uint256 _amount) public evolutionLock(_msgSender()) {
        lastEvolution[_msgSender()] = block.timestamp;
        pika().transferFrom(_msgSender(), address(this), _amount);
        // burn
        uint256 burnedAmount = _calculateFee(_amount, 6500);
        pika().burn(burnedAmount);
        // staking
        address pikaStaking = 0xd7FAac163c38cE303459089153F9C6f29b17f0BC;
        uint256 stakingReward = _calculateFee(_amount, 500);
        pika().transfer(pikaStaking, stakingReward);
        // liquidity
        (address liquidityAddress, uint256 liquidityFee) = unpackBeneficiary(liquidity);
        if (liquidityFee != 0) {
            liquidityFee = _calculateFee(_amount, liquidityFee) / 10000;
            _mint(liquidityAddress, liquidityFee);
        }
        // game rewards
        uint256 rewardPoolAmount = _calculateFee(_amount, 3000);
        address rewardPool = 0xd657d402e12cF2619d40b1B5069818B2989f17B4;
        pika().transfer(rewardPool, rewardPoolAmount);
        _mint(_msgSender(), _amount / 10000);
        emit Evolved(_msgSender(), _amount);
    }

    receive() external payable {
        // Do nothing
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override evolutionLock(sender) {
        // add liquidity
        // user => pair, _msgSender() = router

        // remove liquidity
        // pair => router, _msgSender() = pair
        // router => user, _msgSender() = router

        // buy tokens for eth
        // pair => user, _msgSender() = pair

        // sell tokens for eth
        // user => pair, _msgSender() = router
        address pair = uniswapPair;
        // don't take a fee when
        // 1. fees are disabled
        // 2. the uniswap pair is neither sender nor recipient (non uniswap buy or sell)
        // 3. sender or recipient is excluded from fees
        // 4. sender is pair and recipient is router (2 transfers take place when liquidity is removed)
        if (
            !feesEnabled ||
            (sender != pair && recipient != pair) ||
            isExcludedFromFee[sender] ||
            isExcludedFromFee[recipient] ||
            (sender == pair && recipient == address(router()))
        ) {
            ERC20Upgradeable._transfer(sender, recipient, amount);
            return;
        }

        uint256 burnedAmount = _calculateFee(25, amount);
        _burn(sender, burnedAmount);

        // get fees and recipients from storage
        (address beneficiaryAddress, uint256 transferFee) = unpackBeneficiary(beneficiary);
        if (transferFee > 0) {
            transferFee = handleFeeTransfer(sender, amount, beneficiaryAddress, transferFee);

            // don't autoswap when uniswap pair or router are sending tokens
            if (swapEnabled && sender != pair && sender != address(router())) {
                _swapTokensForEth(address(this));
                // if there are any ETH in the contract distribute rewards
                uint256 ethBalance = address(this).balance;
                (address stakingContract, uint256 stakingFee) = unpackBeneficiary(staking);
                uint256 stakingRewards = _calculateFee(ethBalance, stakingFee);
                if (stakingRewards > 0) {
                    _safeTransfer(stakingContract, stakingRewards);
                }
                _safeTransfer(beneficiaryAddress, ethBalance - stakingRewards);
            }
        }

        ERC20Upgradeable._transfer(sender, recipient, amount - transferFee - burnedAmount);
    }

    function _safeTransfer(address _to, uint256 _value) internal {
        (bool success, ) = _to.call{value: _value}("");
        require(success, string(abi.encodePacked("ETH_TRANSFER_FAILED: ", uint256(uint160(_to)).toHexString(20))));
    }

    uint256[50] private __gap;
}