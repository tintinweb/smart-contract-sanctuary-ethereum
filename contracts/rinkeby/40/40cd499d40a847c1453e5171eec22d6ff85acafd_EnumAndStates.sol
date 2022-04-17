/**
 *Submitted for verification at Etherscan.io on 2022-04-17
*/

contract EnumAndStates { //Usint Enums and states to keep the smart contract good
    enum State { Waiting, Ready, Active }
    
    State public state;

    constructor() {
        state = State.Waiting;
    }

    function activate() public {
        state = State.Active;
    }

    function IsActive() public view returns(bool){
        return state == State.Active;
    }
}