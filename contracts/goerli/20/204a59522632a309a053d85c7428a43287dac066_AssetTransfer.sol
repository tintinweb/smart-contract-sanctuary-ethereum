/**
 *Submitted for verification at Etherscan.io on 2022-04-07
*/

pragma solidity ^0.5.0;

contract AssetTransfer {
    enum StateType {
        Unknown,
        Pending,
        OnShelf,
        Scheduled,
        Exited
    }

    event AssetCreated (string assetName, uint16 externalId, address originatingAddress);
    event AssetTransitioned (StateType previousState, StateType newState);
    event AssetFrozen ();

    address private Owner;
    string public Name;
    uint16 public ExternalId;
    StateType public CurrentState;
    bool public IsFrozen;

    constructor (string memory name, uint16 externalId, StateType initialState) public {
        Owner = msg.sender;
        Name = name;
        ExternalId = externalId;
        CurrentState = initialState;

        emit AssetCreated(Name, ExternalId, msg.sender);
    }

    function ChangeState(StateType newState) public {
        require(!IsFrozen);
        require(Owner == msg.sender);
        StateType previousState = CurrentState;
        CurrentState = newState;

        emit AssetTransitioned(previousState, CurrentState);
    }

    function Freeze() public {
        require(!IsFrozen);
        require(Owner == msg.sender);

        IsFrozen = true;
        emit AssetFrozen();
    }

    function Transfer(address newOwner) public {
        require(!IsFrozen);
        require(Owner == msg.sender);

        Owner = newOwner;
    }
}