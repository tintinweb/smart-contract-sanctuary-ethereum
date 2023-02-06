/**
 *Submitted for verification at Etherscan.io on 2023-02-06
*/

//SPDX-License-Identifier: Unlicense
pragma solidity 0.5.15;

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
    function balanceOf(address dst) external view returns(uint256);
}

interface PotLike {
    function pie(address guy) external view returns(uint256);
    function Pie() external view returns(uint256);
    function chi() external view returns(uint256);
    function dsr() external view returns(uint256);
    function vat() external view returns(address);
    function rho() external view returns(uint256);
    function drip() external returns (uint256 tmp);
    function join(uint256) external;
    function exit(uint256) external;
}

contract DssSavingReward  {
    // --- Auth ---
    mapping (address => uint256) public wards;
    function rely(address guy) external  auth { wards[guy] = 1; }
    function deny(address guy) external  auth { wards[guy] = 0; }
   
    modifier auth {
        require(wards[msg.sender] == 1, "DSReward/not-authorized");
        _;
    }

    // --- event ---
    event EnterStaking(address indexed who, uint256 wad, uint256 dai, uint256 gov);
    event LeaveStaking(address indexed who, uint256 wad, uint256 dai, uint256 gov);
    event Harvest(address indexed who, uint256 dai, uint256 gov);
    

    // --- Data ---
    struct UserInfo{
        uint256 amount;   // Stake HGBP amount
        uint256 pie;      // Pot Normalised Savings HGBP 
        uint256 gie;      // Gov Normalised Savings HGBP
    }

    mapping (address => UserInfo) public userInfo; 
    uint256 public supply;// Total Stake Amount            [wad]
    uint256 public reward;// The rewards that have been generated
    uint256 public Pie;   // Total Normalised Savings on pot  [wad]
    uint256 public Gie;   // Total Normalised Savings Dai  [wad]
    uint256 public dsr;   // The Gov Savings Rate          [ray]
    uint256 public chi;   // The Rate Accumulator          [ray]
    uint256 public dust;  // The min Saving                [wad]

    GovLike public gov;   // Governance Token
    PotLike public pot;   // Savings Engine
    GemLike public dai;   // HGBP
    JoinLike public daiJoin; 

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
        dust = 10e18;
        VatLike vat = VatLike(pot.vat());
        vat.hope(daiJoin_);
        vat.hope(pot_);
        dai.approve(daiJoin_, uint256(-1));
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
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "DSReward/add-overflow");
    }
    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "DSReward/sub-overflow");
    }
    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "DSReward/mul-overflow");
    }
    function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = mul(x, y) / ONE;
    }
    function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        // always rounds down
        z = mul(x, ONE) / y;
    }
    function rdivup(uint256 x, uint256 y) internal pure returns (uint256 z) {
        // always rounds up
        z = add(mul(x, ONE), sub(y, 1)) / y;
    }
    

    // --- Administration ---
    function file(bytes32 what, uint256 data) external auth {
        require(live == 1, "DSReward/not-live");
        if (what == "dust") dust = data;
        else if (what == "dsr") {drip() ;dsr = data;}
        else revert("DSReward/file-unrecognized-param");
    }


    function cage() external  auth {
        live = 0;
        dsr = ONE;
    }

    function exit() external auth {
        require(live==0, "DSReward/invalid-live");
        gov.transfer(msg.sender ,sub(balanceGov(), reward));
    }

    function balanceGov() public view returns (uint256 wad){
        return gov.balanceOf(address(this));
    }

    function daiParms() public view returns (uint256 chi_, uint256 dsr_, uint256 rho_){
        return (pot.chi(), pot.dsr(), pot.rho());
    }

    function govParms() public view returns (uint256 chi_, uint256 dsr_, uint256 rho_){
        return (chi, dsr, rho);
    }

    // --- Savings Rate Accumulation ---
    function drip() public returns (uint256 tmp) {
        require(now >= rho, "DSReward/invalid-now");
        tmp = rmul(rpow(dsr, now - rho, ONE), chi);
        uint256 chi_ = sub(tmp, chi);
        uint256 reward_ = rmul(Gie, chi_);
        if (reward_ <= balanceGov()){
            reward = add(reward,  rmul(Gie, chi_)); 
            chi = tmp;
        } 
        rho = now;
    }

    // --- Calculated Rewards ---
    function rewardAmounts(address usr, uint256 chi_, uint256 pot_chi) public view returns (uint256 gov_, uint256 dai_){
        if (userInfo[usr].amount > 0){
            gov_ = sub(rmul(userInfo[usr].gie, chi_), userInfo[usr].amount);
            dai_ = sub(rmul(userInfo[usr].pie, pot_chi), userInfo[usr].amount);
        }
    }

    function enterStaking(uint256 wad) public {
        require(wad >= dust, "DSReward/invalid-wad");
        uint256 pot_chi = (now > pot.rho()) ? pot.drip() : pot.chi(); drip();
        UserInfo storage usr = userInfo[msg.sender];
        uint256 pie_; uint256 gov_; uint256 dai_ ;
        if (usr.amount > 0){
            (gov_, dai_) = rewardAmounts(msg.sender, chi, pot_chi);

            //withdraw gov reward
            Gie     = sub(Gie,  usr.gie);
            gov.transfer(msg.sender, gov_);
            
            //withdraw dai reward
            pie_ = rdivup(dai_, pot_chi);
            usr.pie = sub(usr.pie, pie_);
            Pie     = sub(Pie,     pie_);
            pot.exit(pie_);
            dai_ = rmul(pie_, pot_chi);
            daiJoin.exit(msg.sender, dai_);
        }
    
        //join
        dai.transferFrom(msg.sender, address(this), wad);
        daiJoin.join(address(this), wad);
        pie_ = rdiv(wad,   pot_chi);
        pot.join(pie_);

        //update
        usr.amount   = add(usr.amount,  wad);
        supply       = add(supply,      wad);
        usr.pie      = add(usr.pie,     pie_);
        Pie          = add(Pie,         pie_);
        usr.gie      = rdiv(usr.amount, chi);
        Gie          = add(Gie,         usr.gie);

        emit EnterStaking(msg.sender, wad, dai_, gov_);
    }


    function leaveStaking(uint256 wad) public {
        uint256 pot_chi = (now > pot.rho()) ? pot.drip() : pot.chi(); drip();
        UserInfo storage usr = userInfo[msg.sender];
        require(sub(usr.amount, wad) >= dust || wad == usr.amount , "DSReward/invalid-wad");
        if (wad == usr.amount){
            leaveAllStaking();
        }else {
            (uint256 gov_, uint256 dai_) = rewardAmounts(msg.sender, chi, pot_chi);
            uint256 pie_;
            {
                //withdraw gov reward
                Gie     = sub(Gie, usr.gie);
                gov.transfer(msg.sender, gov_);

                //withdraw dai reward
                pie_ = rdivup(dai_, pot_chi);
                usr.pie = sub(usr.pie, pie_);
                Pie     = sub(Pie, pie_);

                pot.exit(pie_);
                dai_ = rmul(pie_, pot_chi);
                daiJoin.exit(msg.sender, dai_);
            }
            
            //exit
            pie_ = rdivup(wad, pot_chi);
            pot.exit(pie_);
            uint256 amt = rmul(pie_, pot_chi);
            daiJoin.exit(msg.sender,  amt);

            //update
            usr.amount   = sub(usr.amount,  wad);
            supply       = sub(supply,      wad);
            usr.pie      = sub(usr.pie,     pie_);
            Pie          = sub(Pie,         pie_);
            usr.gie      = rdiv(usr.amount, chi);
            Gie          = add(Gie,         usr.gie);

            emit LeaveStaking(msg.sender, wad, dai_, gov_);
        }
    }

    function leaveAllStaking() public {
        uint256 pot_chi = (now > pot.rho()) ? pot.drip() : pot.chi(); drip();
        UserInfo storage usr = userInfo[msg.sender];
        (uint256 gov_, uint256 dai_) = rewardAmounts(msg.sender, chi, pot_chi);

        //withdraw gov reward
        Gie     = sub(Gie, usr.gie);
        gov.transfer(msg.sender, gov_);

        //withdraw dai reward & amount 
        Pie =  sub(Pie, usr.pie);
        pot.exit(usr.pie);
        uint256 amt = rmul(usr.pie, pot_chi);
        daiJoin.exit(msg.sender,  amt);

        emit LeaveStaking(msg.sender, usr.amount, dai_, gov_);

        //update
        supply       = sub(supply,    usr.amount);
        delete userInfo[msg.sender];
    }

    function harvest() public {
        uint256 pot_chi = (now > pot.rho()) ? pot.drip() : pot.chi(); drip();
        UserInfo storage usr = userInfo[msg.sender];
        require(usr.amount > 0, "DSReward/invalid");
        (uint256 gov_, uint256 dai_) = rewardAmounts(msg.sender, chi, pot_chi);

        //withdraw gov reward
        uint256 gie_ = rdivup(gov_, chi);
        usr.gie = sub(usr.gie, gie_);
        Gie     = sub(Gie,     gie_);
        gov.transfer(msg.sender, gov_);

        //withdraw dai reward
        uint256 pie_ = rdivup(dai_, pot_chi);
        usr.pie = sub(usr.pie, pie_);
        Pie     = sub(Pie,     pie_);
        pot.exit(pie_);
        dai_ = rmul(pie_, pot_chi);
        daiJoin.exit(msg.sender, dai_);

        emit Harvest(msg.sender, dai_, gov_);
    }
}