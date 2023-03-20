// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface ILaunchpad {
    function getLaunchpadSlotInfo(bytes4 /* proxyId */, bytes4 launchpadId, uint256 slotId) external view returns (
        bool[] memory boolData,
        uint256[] memory intData,
        address[] memory addressData,
        bytes4[] memory bytesData
    );
}

interface IElemetas {
    function totalSupply() external view returns(uint256);
    function maxMintAmountPerUser() external view returns(uint256);
    function userMinted(address user) external view returns(uint256);
}

contract ElemetasHelper  {
    struct SlotId {
        bytes4 launchpadId;
        uint256 slotId;
    }

    struct Slot {
        bool enable;
        uint256 whiteListModel;
        uint256 price;
        uint256 saleStart;
        uint256 saleEnd;
    }

    struct Returns {
        uint256 userBalance;
        uint256 userMintedAmount;
        uint256 maxMintAmountPerUser;
        uint256 totalSupply;
        address targetContract;
        Slot[] slots;
    }

    address private constant NULL_ADDRESS = 0x0000000000000000000000000000000000000000;

    function query(
        address account,
        address targetContract,
        ILaunchpad launchpad,
        SlotId[] calldata ids
    ) external view returns(Returns memory r) {
        Slot[] memory slots = new Slot[](ids.length);
        for (uint256 i; i < ids.length; i++) {
            (
                bool[] memory boolData,
                uint256[] memory intData,
                address[] memory addressData,
            ) = launchpad.getLaunchpadSlotInfo(0, ids[i].launchpadId, ids[i].slotId);
            slots[i].enable = boolData[0];
            slots[i].whiteListModel = intData[1];
            slots[i].saleStart = intData[0];
            slots[i].saleEnd = intData[9];
            slots[i].price = intData[12];
            if (addressData[1] != NULL_ADDRESS) {
                targetContract = addressData[1];
            }
        }
        r.slots = slots;
        if (account != NULL_ADDRESS) {
            r.userBalance = account.balance;
        }

        if (targetContract != NULL_ADDRESS) {
            r.targetContract = targetContract;
            IElemetas elemetas = IElemetas(targetContract);
            r.totalSupply = elemetas.totalSupply();
            r.maxMintAmountPerUser = elemetas.maxMintAmountPerUser();
            if (account != NULL_ADDRESS) {
                r.userMintedAmount = elemetas.userMinted(account);
            }
        }
        return r;
    }
}