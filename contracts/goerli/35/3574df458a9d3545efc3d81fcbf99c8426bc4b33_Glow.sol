// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface Gusd {
    function balanceOf(address _owner) external view returns (uint256);

    function approve(address _addr, uint256 _amt) external returns (bool);

    function transfer(address _to, uint256 _value) external returns (bool);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool);

    function allowance(address _owner, address _spender)
        external
        returns (uint256);
}

interface Dai {
    function balanceOf(address) external returns (uint256);

    function approve(address usr, uint256 wad) external returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) external returns (bool);

    function allowance(address _owner, address _spender)
        external
        returns (uint256);
}

interface DssPsm {
    function sellGem(address usr, uint256 gemAmt) external;
}

interface DaiJoin {
    function join(address usr, uint256 wad) external;
}

interface ChainLogLike {
    function getAddress(bytes32) external view returns (address);
}

contract Glow {
    ChainLogLike public immutable changelog;
    Gusd public immutable gusd;
    Dai public immutable dai;
    DssPsm public immutable gusdPsm;
    DaiJoin public immutable daiJoin;

    address gusdAddress;
    address daiAddress;
    address gusdPsmAddress;
    address gusdJoinAddress;
    address daiJoinAddress;
    address vow;

    uint256 public running;

    // --- Events ---
    event Glowed(uint256 amt);
    event RunningTotal(uint256 amt);
    event Quit(uint256 amt);

    constructor(address chainlog_) {
        changelog = ChainLogLike(chainlog_);

        gusdAddress = changelog.getAddress("GUSD");
        daiAddress = changelog.getAddress("MCD_DAI");
        gusdPsmAddress = changelog.getAddress("MCD_PSM_GUSD_A");
        gusdJoinAddress = changelog.getAddress("MCD_JOIN_PSM_GUSD_A");
        daiJoinAddress = changelog.getAddress("MCD_JOIN_DAI");
        vow = changelog.getAddress("MCD_VOW");

        gusd = Gusd(gusdAddress);
        dai = Dai(daiAddress);
        gusdPsm = DssPsm(gusdPsmAddress);
        daiJoin = DaiJoin(daiJoinAddress);

        gusd.approve(gusdJoinAddress, 2**256 - 1);
        dai.approve(daiJoinAddress, 2**256 - 1);
    }

    /// @dev Pulls GUSD from the wallet of the user and only sends that amount of Dai
    function glow(uint256 amt_) public {
        gusd.transferFrom(msg.sender, address(this), amt_);

        gusdPsm.sellGem(address(this), amt_);

        uint256 dbalance = dai.balanceOf(address(this));
        running += dbalance;
        daiJoin.join(vow, dbalance);
        emit Glowed(dbalance);
        emit RunningTotal(running);
    }

    /// @dev Sweeps the balance of GUSD on the contract
    function glow() public {
        uint256 gbalance = gusd.balanceOf(address(this));
        gusdPsm.sellGem(address(this), gbalance);

        uint256 dbalance = dai.balanceOf(address(this));
        running += dbalance;
        daiJoin.join(vow, dbalance);
        emit Glowed(dbalance);
        emit RunningTotal(running);
    }

    function quit() public {
        uint256 gbalance = gusd.balanceOf(address(this));
        gusd.transfer(changelog.getAddress("MCD_PAUSE_PROXY"), gbalance);
        emit Quit(gbalance);
    }
}