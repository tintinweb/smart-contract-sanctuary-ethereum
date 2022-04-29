// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../base/DRIP20.sol";

contract DRIPToken is DRIP20 {
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _emissionRatePerBlock
    ) DRIP20(_name, _symbol, _decimals, _emissionRatePerBlock) {}

    function mint(uint256 amount) external {
        _mint(msg.sender, amount);
    }

    function startDripping(address addr) external virtual {
        _startDripping(addr);
    }

    function stopDripping(address addr) external virtual {
        _stopDripping(addr);
    }

    function burn(address from, uint256 value) external virtual {
        _burn(from, value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

///@author 0xBeans
///@notice This is an ERC20 implementation that supports constant token emissions (drips) to wallets.
///@notice This allows tokens to be streamed/dripped to users per block via an emission rate without users
///@notice ever having to send a separate transaction to 'claim' tokens.
///@notice shout out to solmate (@t11s) for the slim and efficient ERC20 implementation!
///@notice shout out to superfluid and UBI for the dripping inspiration!

abstract contract DRIP20 {
    /*==============================================================
    ==                            EVENTS                          ==
    ==============================================================*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );

    /*==============================================================
    ==                      METADATA STORAGE                      ==
    ==============================================================*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*==============================================================
    ==                       ERC20 STORAGE                        ==
    ==============================================================*/

    mapping(address => mapping(address => uint256)) public allowance;

    /*==============================================================
    ==                        DRIP STORAGE                        ==
    ==============================================================*/

    // immutable token emission rate per block
    uint256 public immutable emissionRatePerBlock;

    mapping(address => uint256) private _balance;

    mapping(address => uint256) private _accrualStartBlock;

    // these are all used for calculating totalSupply()
    uint256 private _currAccrued;
    uint256 private _currEmissionBlockNum;
    uint256 private _currNumAccruers;

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _emissionRatePerBlock
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        emissionRatePerBlock = _emissionRatePerBlock;
    }

    /*==============================================================
    ==                        ERC20 IMPL                          ==
    ==============================================================*/

    function approve(address spender, uint256 amount)
        public
        virtual
        returns (bool)
    {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(to != address(0), "ERC20: transfer to the zero address");

        _balance[from] = balanceOf(from) - amount;

        unchecked {
            _balance[to] += amount;
        }

        if (_accrualStartBlock[from] != 0) {
            _accrualStartBlock[from] = block.number;
        }

        emit Transfer(from, to, amount);
    }

    function transfer(address to, uint256 amount)
        public
        virtual
        returns (bool)
    {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max)
            allowance[from][msg.sender] = allowed - amount;

        _transfer(from, to, amount);

        return true;
    }

    function balanceOf(address addr) public view returns (uint256) {
        uint256 addrAccrualStartBlock = _accrualStartBlock[addr];
        uint256 accruedBalance = _balance[addr];

        if (addrAccrualStartBlock == 0) {
            return accruedBalance;
        }

        return
            ((block.number - addrAccrualStartBlock) * emissionRatePerBlock) +
            accruedBalance;
    }

    function totalSupply() public view returns (uint256) {
        return
            _currAccrued +
            (block.number - _currEmissionBlockNum) *
            emissionRatePerBlock *
            _currNumAccruers;
    }

    /*==============================================================
    ==                        DRIP LOGIC                          ==
    ==============================================================*/

    /**
     * @dev Add an address to start dripping tokens to.
     * @dev We need to update _currAccrued whenever we add a new dripper to properly update totalSupply()
     * @dev IMPORTANT: Can only call this on an address thats not accruing
     * @param addr address to drip to
     */
    function _startDripping(address addr) internal virtual {
        require(_accrualStartBlock[addr] == 0, "user already accruing");
        _currAccrued = totalSupply();
        _currEmissionBlockNum = block.number;

        unchecked {
            _currNumAccruers++;
        }
        _mint(addr,0);

        _accrualStartBlock[addr] = block.number;
    }

    /**
     * @dev Add an address to stop dripping tokens to.
     * @dev We need to update _currAccrued whenever we remove a dripper to properly update totalSupply()
     * @dev IMPORTANT: Can only call this on an address that is accruing
     * @param addr address to stop dripping to
     */
    function _stopDripping(address addr) internal virtual {
        require(_accrualStartBlock[addr] != 0, "user not accruing");
        _balance[addr] = balanceOf(addr);
        _currAccrued = totalSupply();
        _currEmissionBlockNum = block.number;
        _currNumAccruers--;
        _accrualStartBlock[addr] = 0;
    }

    /*==============================================================
    ==                         MINT/BURN                          ==
    ==============================================================*/

    function _mint(address to, uint256 amount) internal virtual {
        unchecked {
            _currAccrued += amount;
            _balance[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        // have to update supply before burning
        _currAccrued = totalSupply();
        _currEmissionBlockNum = block.number;
        _balance[from] = balanceOf(from) - amount;

        // Cannot underflow because amount can
        // never be greater than the totalSupply()
        unchecked {
            _currAccrued -= amount;
        }

        if (_accrualStartBlock[from] != 0) {
            _accrualStartBlock[from] = block.number;
        }

        emit Transfer(from, address(0), amount);
    }
}