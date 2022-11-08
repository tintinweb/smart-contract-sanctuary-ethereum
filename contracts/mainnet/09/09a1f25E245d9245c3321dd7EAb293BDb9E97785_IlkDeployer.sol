/**
 *Submitted for verification at Etherscan.io on 2022-11-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface SpotterLike {
    function poke(bytes32) external;
}
interface DSValueAbstract {
    function init() external;
    function poke(bytes32 wut) external;
}
interface IlkRegistryAbstract {
    function add(address) external;
}
interface IProxy {
    function changeAdmin(address newAdmin) external returns(bool);
    function upgrad(address newLogic) external returns(bool);
}
interface DSTokenAbstract {
    function decimals() external view returns (uint256);
}
interface DssSpellAbstract {
    function schedule() external;
    function cast() external;
}
interface GemJoinAbstract {
    function init(address vat_, bytes32 ilk_, address gem_) external;
    function vat() external view returns (address);
    function ilk() external view returns (bytes32);
    function gem() external view returns (address);
    function dec() external view returns (uint256);
}
interface PauseLike {
    function delay() external returns (uint);
    function proxy() external view returns (address);
    function exec(address, bytes32, bytes memory, uint256) external;
    function plot(address, bytes32, bytes memory, uint256) external;
}
interface FlipAbstract {
    function init(address vat_, address cat_, bytes32 ilk_) external;
    function rely(address usr) external;
    function vat() external view returns (address);
    function cat() external view returns (address);
    function ilk() external view returns (bytes32);
}
interface ConfigLike {
    function init(bytes32) external;
    function file(bytes32, uint256) external;
    function file(bytes32, bytes32, address) external;
    function file(bytes32, bytes32, uint) external;
    function rely(address) external;
}

contract IlkDeployer {
    // decimals & precision
    uint256 constant public WAD = 10 ** 18;
    uint256 constant public RAY = 10 ** 27;
    uint256 constant public RAD = 10 ** 45;
    function deploy(bytes32 ilk_, address[11] calldata addrs, uint[9] calldata vals) external {
        // addrs[0] = vat
        // addrs[1] = cat
        // addrs[2] = jug
        // addrs[3] = spotter
        // addrs[4] = end
        // addrs[5] = join
        // addrs[6] = pip
        // addrs[7] = flip
        // addrs[8] = IlkRegistry
        // addrs[9] = gem
        // addrs[10] = FLIPPER_MOM

        // vals[0] = line
        // vals[1] = mat
        // vals[2] = duty
        // vals[3] = chop
        // vals[4] = dunk
        // vals[5] = dust
        // vals[6] = beg
        // vals[7] = ttl
        // vals[8] = tau
        require(GemJoinAbstract(addrs[5]).vat() == addrs[0], "join-vat-not-match");
        require(GemJoinAbstract(addrs[5]).ilk() == ilk_, "join-ilk-not-match");
        require(GemJoinAbstract(addrs[5]).gem() == addrs[9], "join-gem-not-match");
        require(GemJoinAbstract(addrs[5]).dec() == DSTokenAbstract(addrs[9]).decimals(), "join-dec-not-match");
        require(FlipAbstract(addrs[7]).vat() == addrs[0], "flip-vat-not-match");
        require(FlipAbstract(addrs[7]).cat() == addrs[1], "flip-cat-not-match");
        require(FlipAbstract(addrs[7]).ilk() == ilk_, "flip-ilk-not-match");

        ConfigLike(addrs[3]).file(ilk_, "pip", address(addrs[6])); // vat.file(ilk_, "pip", pip);

        ConfigLike(addrs[1]).file(ilk_, "flip", addrs[7]); // cat.file(ilk_, "flip", flip);
        ConfigLike(addrs[0]).init(ilk_); // vat.init(ilk_);
        ConfigLike(addrs[2]).init(ilk_); // jug.init(ilk_);

        ConfigLike(addrs[0]).rely(addrs[5]); // vat.rely(join);
        ConfigLike(addrs[1]).rely(addrs[7]); // cat.rely(flip);
        ConfigLike(addrs[7]).rely(addrs[1]); // flip.rely(cat);
        ConfigLike(addrs[7]).rely(addrs[4]); // flip.rely(end);
        ConfigLike(addrs[7]).rely(addrs[10]); // flip.rely(FlipperMom);

        ConfigLike(addrs[0]).file(ilk_, "line", vals[0] * RAD); // vat.file(ilk_, "line", line);
        ConfigLike(addrs[0]).file(ilk_, "dust", vals[5] * RAD); // vat.file(ilk_, "dust", dust);
        ConfigLike(addrs[1]).file(ilk_, "dunk", vals[4] * RAD); // cat.file(ilk_, "dunk", dunk);
        ConfigLike(addrs[1]).file(ilk_, "chop", (100 + vals[3]) * WAD / 100); // cat.file(ilk_, "chop", chop);
        //ConfigLike(addrs[2]).file(ilk_, "duty", (100 + vals[2]) * RAY / 100); // jug.file(ilk_, "duty", duty);//1000000001547125957863212448
        ConfigLike(addrs[2]).file(ilk_, "duty", vals[2]); // jug.file(ilk_, "duty", duty);
        ConfigLike(addrs[7]).file("beg", (100 + vals[6]) * WAD / 100); // flip.file("beg", beg);
        ConfigLike(addrs[7]).file("ttl", vals[7]); // flip.file("ttl", ttl);
        ConfigLike(addrs[7]).file("tau", vals[8]); // flip.file("tau", tau);
        ConfigLike(addrs[3]).file(ilk_, "mat", vals[1] * RAY / 100); // spotter.file(ilk_, "mat", mat);

        // Update spot value in Vat
        SpotterLike(addrs[3]).poke(ilk_); // spotter.poke(ilk_);
        // Add new ilk to the IlkRegistry
        IlkRegistryAbstract(addrs[8]).add(addrs[5]);
    }
}