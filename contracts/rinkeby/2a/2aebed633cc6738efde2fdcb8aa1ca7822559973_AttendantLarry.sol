// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./ILockerRoomAttendant.sol";
import "./IExpansion.sol";

/*
    Larry is a good chap. Wants to do right by his clientele.
    Takes his job as "Keeper of the Goods" seriously.
    Doesn't allow funny business.
*/
contract AttendantLarry is ILockerRoomAttendant {
    // IExpansion => bool
    mapping(IExpansion => bool) _expansions;

    // avatarId => AvatarAttachment[]
    mapping(uint256 => AvatarAttachment[]) _attachments;

    // owner => (expansion => (id => amount))
    mapping(address => mapping(IExpansion => mapping(uint256 => uint256))) _attachedByOwner;

    function registerExpansion(IExpansion expansion) public {
        _expansions[expansion] = true;
    }

    function enrobe(
        uint256 avatarId,
        IExpansion[] calldata expansions,
        uint256[] calldata expansionIds,
        uint256[] calldata expansionAmounts
    ) public {
        uint256 length = expansions.length;
        require(length == expansionIds.length, "Array length mismatch");

        address owner = msg.sender;

        AvatarAttachment[] memory priorAttachments = _attachments[avatarId];
        uint256 priorAttachmentsLength = priorAttachments.length;

        // Undo prior attachment balances - these will be recalculated
        for (uint256 i = 0; i < priorAttachmentsLength; i++) {
            AvatarAttachment memory attachment = priorAttachments[i];
            _attachedByOwner[owner][attachment.expansion][
                attachment.expansionId
            ] -= attachment.amount;
        }

        // Clear prior attachments - these will be reconstructed
        delete _attachments[avatarId];

        for (uint256 i = 0; i < length; i++) {
            AvatarAttachment memory attachment = AvatarAttachment({
                expansion: expansions[i],
                expansionId: expansionIds[i],
                amount: expansionAmounts[i]
            });

            _attachments[avatarId].push(attachment);

            _attachedByOwner[owner][attachment.expansion][
                attachment.expansionId
            ] += attachment.amount;
        }
    }

    function totalExpansions(uint256 avatarId) public view returns (uint256) {
        return _attachments[avatarId].length;
    }

    function expansionAtIndex(uint256 avatarId, uint256 index)
        public
        view
        returns (
            IExpansion,
            uint256,
            uint256
        )
    {
        AvatarAttachment memory attachment = _attachments[avatarId][index];

        return (
            attachment.expansion,
            attachment.expansionId,
            attachment.amount
        );
    }

    function afterAvatarTokenTransfer(
        address from,
        address to,
        uint256 avatarId
    ) public {
        AvatarAttachment[] memory attachments = _attachments[avatarId];
        uint256 length = attachments.length;

        for (uint256 i = 0; i < length; i++) {
            IExpansion expansion = attachments[i].expansion;
            uint256 expansionId = attachments[i].expansionId;
            uint256 amount = attachments[i].amount;

            _attachedByOwner[from][expansion][expansionId] -= amount;
            _attachedByOwner[to][expansion][expansionId] += amount;

            expansion.expansionSafeTransferFrom(
                from,
                to,
                expansionId,
                amount,
                "AttendantLarry: Attachment transfer"
            );
        }
    }

    function beforeExpansionTokenTransfer(
        address,
        address from,
        address,
        uint256[] memory ids,
        uint256[] memory amounts,
        uint256[] memory balances,
        bytes memory
    ) public view {
        // If the transfer would put the attachments in a negative balance, cancel the transaction
        IExpansion expansion = IExpansion(address(msg.sender));
        uint256 length = ids.length;

        for (uint256 i = 0; i < length; i++) {
            uint256 newBalance = balances[i] - amounts[i];
            uint256 current = _attachedByOwner[from][expansion][ids[i]];
            require(
                newBalance >= current,
                "AttendantLarry: Insufficient balance to transfer; remove attachments and try again."
            );
        }
    }

    function countAttached(address owner, uint256 id)
        public
        view
        returns (uint256)
    {
        IExpansion expansion = IExpansion(address(msg.sender));
        return _attachedByOwner[owner][expansion][id];
    }
}

struct AvatarAttachment {
    IExpansion expansion;
    uint256 expansionId;
    uint256 amount;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./IExpansion.sol";

interface ILockerRoomAttendant {
    // Attendant controls what happens after an avatar is transferred (e.g. also transfer expansion items)
    function afterAvatarTokenTransfer(
        address from,
        address to,
        uint256 avatarId
    ) external;

    // Attendant controls what happens before expansion items are transferred (e.g. prevent transfer if attached)
    function beforeExpansionTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        uint256[] memory balances,
        bytes memory data
    ) external;

    // Attendant tracks which items are attached (e.g. for checking balances)
    function countAttached(address owner, uint256 id)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./ILockerRoomAttendant.sol";

interface IExpansion {
    function expansionSafeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    function replaceAttendant(ILockerRoomAttendant newAttendant) external;
}