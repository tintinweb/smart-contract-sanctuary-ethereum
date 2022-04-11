/*
 SPDX-License-Identifier: MIT
*/

pragma solidity ^0.8.4;

/**
 * @author Publius
 * @title BeanStalkGetters provides an interface to load particular data.
**/

interface IBS {
    struct Bip {
        address proposer;
        uint32 start;
        uint32 period;
        bool executed;
        int pauseOrUnpause;
        uint128 timestamp;
        uint256 roots;
        uint256 endTotalRoots;
    }

    struct Fundraiser {
        address payee;
        address token;
        uint256 total;
        uint256 remaining;
        uint256 start;
    }

    function totalRoots() external view returns (uint256);
    function season() external view returns (uint32);

    function numberOfBips() external view returns (uint32);
    function bip(uint32 bipId) external view returns (Bip memory);
    function voted(address account, uint32 bipId) external view returns (bool);
    function activeBips() external view returns (uint32[] memory);

    function numberOfFundraisers() external view returns (uint32);
    function fundraiser(uint32 id) external view returns (Fundraiser memory);
}

contract BeanstalkGetters {
    struct Bip {
        address proposer;
        uint32 start;
        uint32 period;
        bool executed;
        int pauseOrUnpause;
        uint128 timestamp;
        uint256 roots;
        uint256 totalRoots;
        bool active;
    }

    struct Vote {
        uint32 bipId;
        bool vote;
    }

    IBS private constant beanstalk = IBS(0xC1E088fC1323b20BCBee9bd1B9fC9546db5624C5);

    function bips() external view returns (Bip[] memory bs) {
        uint256 totalRoots = beanstalk.totalRoots();
        uint32 numBips = beanstalk.numberOfBips();
        bs = new Bip[](numBips);
        for (uint32 i = 0; i < numBips; i++) {
            bs[i] = convertToBip(beanstalk.bip(i), totalRoots);
        }

        uint32[] memory active = beanstalk.activeBips();
        for (uint256 i = 0; i < active.length; i++) bs[active[i]].active = true;
    }

    function getActiveVotes(address account) external view returns (Vote[] memory vs) {
        uint32[] memory active = beanstalk.activeBips();
        vs = new Vote[](active.length);
        for (uint256 i = 0; i < active.length; i++) {
            vs[i].bipId = active[i];
            vs[i].vote = beanstalk.voted(account, active[i]);
        }
    }

    function fundraisers() external view returns (IBS.Fundraiser[] memory fs) {
        uint32 numFunds = beanstalk.numberOfFundraisers();
        fs = new IBS.Fundraiser[](numFunds);
        for (uint32 i = 0; i < numFunds; i++) {
            fs[i] = beanstalk.fundraiser(i);
        }
    }

    function convertToBip(IBS.Bip memory b0, uint256 totalRoots) private pure returns (Bip memory b1) {
        b1.proposer = b0.proposer;
        b1.start = b0.start;
        b1.period = b0.period;
        b1.executed = b0.executed;
        b1.pauseOrUnpause = b0.pauseOrUnpause;
        b1.timestamp = b0.timestamp;
        b1.roots = b0.roots;
        b1.totalRoots = b0.endTotalRoots > 0 ? b0.endTotalRoots : totalRoots;
        b1.active = false;
    }
}