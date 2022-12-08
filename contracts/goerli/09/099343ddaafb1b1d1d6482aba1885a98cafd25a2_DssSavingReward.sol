/**
 *Submitted for verification at Etherscan.io on 2022-12-08
*/

//SPDX-License-Identifier: Unlicense
pragma solidity >= 0.5.12;

contract LibNote {
    event LogNote(
        bytes4   indexed  sig,
        address  indexed  usr,
        bytes32  indexed  arg1,
        bytes32  indexed  arg2,
        bytes             data
    ) anonymous;

    modifier note {
        _;
        assembly {
            // log an 'anonymous' event with a constant 6 words of calldata
            // and four indexed topics: selector, caller, arg1 and arg2
            let mark := msize()                       // end of memory ensures zero
            mstore(0x40, add(mark, 288))              // update free memory pointer
            mstore(mark, 0x20)                        // bytes type data offset
            mstore(add(mark, 0x20), 224)              // bytes size (padded)
            calldatacopy(add(mark, 0x40), 0, 224)     // bytes payload
            log4(mark, 288,                           // calldata
                 shl(224, shr(224, calldataload(0))), // msg.sig
                 caller(),                            // msg.sender
                 calldataload(4),                     // arg1
                 calldataload(36)                     // arg2
                )
        }
    }
}


interface VatLike {
    function hope(address) external;
}

interface JoinLike {
    function dai() external view returns (address);
    function join(address, uint256) external;
    function exit(address, uint256) external;
}

interface GemLike {
    function transferFrom(address,address,uint256) external returns (bool);
    function approve(address,uint256) external returns (bool);
}

interface GovLike {
    function mint(address guy, uint wad) external;
    function approve(address guy, uint wad)external;
    function transfer(address dst, uint wad) external;
}

interface PotLike {
    function pie(address guy) external returns(uint256);
    function Pie() external returns(uint256);
    function chi() external returns(uint256);
    function vat() external returns(address);
    function rho() external returns(uint256);
    function drip() external returns (uint256 tmp);
    function join(uint256) external;
    function exit(uint256) external;
}

contract DssSavingReward is LibNote  {
    // --- Auth ---
    mapping (address => uint256) public wards;
    function rely(address guy) external note auth { wards[guy] = 1; }
    function deny(address guy) external note auth { wards[guy] = 0; }
   
    modifier auth {
        require(wards[msg.sender] == 1, "DSReward/not-authorized");
        _;
    }

    // --- event ---
    event Reward(address indexed  who, uint256 dai, uint256 gov);
    event Compound(address indexed who, uint256 dai);

    // --- Data ---
    struct UserInfo{
        uint256 amount;   // Stake HGBP amount
        uint256 pie;      // Pot Normalised Savings HGBP 
        uint256 gie;      // Gov Normalised Savings HGBP
    }

    mapping (address => UserInfo) public userInfo; 
    uint256 public supply;// Total Stake Amount            [wad]
    uint256 public Pie;   // Total Normalised Savings on pot  [wad]
    uint256 public Gie;   // Total Normalised Savings Dai  [wad]
    uint256 public dsr;   // The Gov Savings Rate          [ray]
    uint256 public chi;   // The Rate Accumulator          [ray]

    GovLike public gov;   // Governance Token
    PotLike public pot;   // Savings Engine
    GemLike public dai;   // HGBP
    JoinLike public daiJoin; 

    address public vow;   // Debt Engine
    uint256 public rho;   // Time of last drip     [unix epoch time]

    uint256 public live;  // Active Flag

    // --- Init ---
    constructor(address gov_, address pot_,address dai_, address daiJoin_) public {
        wards[msg.sender] = 1;
        gov = GovLike(gov_);
        pot = PotLike(pot_);
        dai = GemLike(dai_);
        daiJoin = JoinLike(daiJoin_);

        dsr = ONE;
        chi = ONE;
        rho = now;
        live = 1;
        VatLike vat = VatLike(pot.vat());
        vat.hope(daiJoin_);
        vat.hope(pot_);
        gov.approve(daiJoin_, uint256(-1));
    }

    // --- Math ---
    uint256 constant private ONE = 10 ** 27;
    function rpow(uint256 x, uint256 n, uint256 base) internal pure returns (uint256 z) {
        assembly {
            switch x case 0 {switch n case 0 {z := base} default {z := 0}}
            default {
                switch mod(n, 2) case 0 { z := base } default { z := x }
                let half := div(base, 2)  // for rounding.
                for { n := div(n, 2) } n { n := div(n,2) } {
                    let xx := mul(x, x)
                    if iszero(eq(div(xx, x), x)) { revert(0,0) }
                    let xxRound := add(xx, half)
                    if lt(xxRound, xx) { revert(0,0) }
                    x := div(xxRound, base)
                    if mod(n,2) {
                        let zx := mul(z, x)
                        if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) { revert(0,0) }
                        let zxRound := add(zx, half)
                        if lt(zxRound, zx) { revert(0,0) }
                        z := div(zxRound, base)
                    }
                }
            }
        }
    }

    function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = mul(x, y) / ONE;
    }
    function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        // always rounds down
        z = mul(x, ONE) / y;
    }
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "DSReward/add-overflow");
    }
    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "DSReward/sub-underflow");
    }
    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "DSReward/mul-overflow");
    }

    // --- Administration ---
    function file(bytes32 what, uint256 data) external note auth {
        require(live == 1, "DSReward/not-live");
        require(now == rho, "DSReward/rho-not-updated");
        if (what == "dsr") dsr = data;
        else revert("DSReward/file-unrecognized-param");
    }

    function file(bytes32 what, address addr) external note auth {
        if (what == "vow") vow = addr;
        else revert("DSReward/file-unrecognized-param");
    }

    function cage() external note auth {
        live = 0;
        dsr = ONE;
    }


    // --- Savings Rate Accumulation ---
    function drip() public note returns (uint256 tmp) {
        require(now >= rho, "DSReward/invalid-now");
        tmp = rmul(rpow(dsr, now - rho, ONE), chi);
        uint256 chi_ = sub(tmp, chi);
        chi = tmp;
        rho = now;
        gov.mint(address(this), rmul(Pie, chi_));
    }


    function enterStaking(uint256 wad) public note {
        uint256 pot_chi = (now > pot.rho()) ? pot.drip() : pot.chi();
        drip();

        UserInfo storage usr = userInfo[msg.sender];
        if (usr.amount > 0 ){
            //withdraw gov reward
            uint256 gov_ = sub(rmul(usr.gie, chi), usr.amount);
            //uint256 gie_ = rdiv(gov_, chi);
            gov.transfer(msg.sender, gov_);
            Gie     = sub(Gie, usr.gie);
            usr.gie = 0;

            //withdraw dai reward
            uint256 dai_ = sub(rmul(usr.pie, pot_chi), usr.amount);
            uint256 pie_ = rdiv(dai_, pot_chi);
            pot.exit(pie_);
            daiJoin.exit(msg.sender, dai_);
            Pie     = sub(Pie, usr.pie);
            usr.pie = 0;
            emit Reward(msg.sender, dai_, gov_);
        }
        
        //join
        dai.transferFrom(msg.sender, address(this), wad);
        daiJoin.join(address(this), wad);
        uint256 pie_ = rdiv(wad,   pot_chi);
        pot.join(pie_);

        //update
        usr.amount   = add(usr.amount,  wad);
        supply       = add(supply,      wad);
        usr.pie      = rdiv(usr.amount, pot_chi);
        Pie          = add(Pie,         usr.pie);
        usr.gie      = rdiv(usr.amount, chi);
        Gie          = add(Gie,         usr.gie);
    }

    function leaveStaking(uint256 wad) public note {
        uint256 pot_chi = (now > pot.rho()) ? pot.drip() : pot.chi();
        drip();

        UserInfo storage usr = userInfo[msg.sender];
        require(usr.amount >= wad, "DSReward/invalid-wad");
        {
            //withdraw gov reward
            uint256 gov_ = sub(rmul(usr.gie, chi), usr.amount);
            //uint256 gie_ = rdiv(gov_, chi);
            gov.transfer(msg.sender, gov_);
            Gie     = sub(Gie, usr.gie);
            usr.gie = 0;

            //withdraw dai reward
            uint256 dai_ = sub(rmul(usr.pie, pot_chi), usr.amount);
            uint256 pie_ = rdiv(dai_, pot_chi);
            pot.exit(pie_);
            daiJoin.exit(msg.sender, dai_);
            Pie     = sub(Pie, usr.pie);
            usr.pie = 0;
            emit Reward(msg.sender, dai_, gov_);
        }
        
        //exit
        uint256 pie_ = rdiv(wad, pot_chi);
        pot.exit(pie_);
        daiJoin.exit(msg.sender, wad);

        //update
        usr.amount   = sub(usr.amount,  wad);
        supply       = sub(supply,      wad);
        usr.pie      = rdiv(usr.amount, pot_chi);
        Pie          = add(Pie,         usr.pie);
        usr.gie      = rdiv(usr.amount, chi);
        Gie          = add(Gie,         usr.gie);
    }

    function harvest() public note {
        uint256 pot_chi = (now > pot.rho()) ? pot.drip() : pot.chi();
        drip();
        UserInfo storage usr = userInfo[msg.sender];
        require(usr.amount > 0, "DSReward/invalid");

        //withdraw gov reward
        uint256 gov_ = sub(rmul(usr.gie, chi), usr.amount);
        uint256 gie_ = rdiv(gov_, chi);
        gov.transfer(msg.sender, gov_);

        usr.gie = sub(usr.gie, gie_);
        Gie     = sub(Gie,  usr.gie);
        
        //withdraw dai reward
        uint256 dai_ = sub(rmul(usr.pie, pot_chi), usr.amount);
        uint256 pie_ = rdiv(dai_, pot_chi);
        pot.exit(pie_);
        daiJoin.exit(msg.sender, dai_);

        usr.pie = sub(usr.pie, pie_);
        Pie     = sub(Pie,     pie_);
        emit Reward(msg.sender, dai_, gov_);
    }


    function compound() public note {
        uint256 pot_chi = (now > pot.rho()) ? pot.drip() : pot.chi();
        drip();
        UserInfo storage usr = userInfo[msg.sender];
        require(usr.amount > 0, "DSReward/invalid");

        //withdraw gov reward
        uint256 gov_ = sub(rmul(usr.gie, chi), usr.amount);
        //uint256 gie_ = rdiv(gov_, chi);
        gov.transfer(msg.sender, gov_);
        Gie     = sub(Gie,  usr.gie);
        usr.gie = 0;
        emit Reward(msg.sender, 0, gov_);


        //compound 
        uint256 dai_ = sub(rmul(usr.pie, pot_chi), usr.amount);
        usr.amount = sub(usr.amount,  dai_);
        supply     = add(supply,      dai_);
        Pie        = sub(Pie,         usr.pie);
        usr.pie    = rdiv(usr.amount, pot_chi);
        Pie        = add(Pie,         usr.pie);
        usr.gie    = rdiv(usr.amount, chi);
        Gie        = add(Gie,         usr.gie);

        emit Compound(msg.sender, dai_);
    }
}