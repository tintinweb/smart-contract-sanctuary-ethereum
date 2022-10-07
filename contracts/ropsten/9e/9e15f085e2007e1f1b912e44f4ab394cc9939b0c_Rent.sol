// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

/*
 * 
 * El pagament es fa a partir de dues adreces que consten en l'estructura del contracte de lloguer. Juntament amb frequencia de pagament i quantitat. 
 * Es comprova si el contracte és per vivenda, ja que en cas de que sigui cert el reglament de contractació és més estricte. 
*/

import "./Persona_Fisica.sol";
import "./Persona_Juridica.sol";
import "./Transfer.sol";
import "./Payment_Request.sol";
import "./Up_Conditions.sol";
import "./Offers.sol";

contract Rent is Persona_Fisica, Persona_Juridica, Transfer, Payment_Request, Up_Conditions, Offers {

    enum rent_state {
        not_started,
        started,
        cancelled,
        surety_pending,
        ended 
    } // when cancelled the end of contract is modified to now + extension. Then is set to ended

    struct Rent_t {
        address landlord;
        address tenant;
        uint frequency;  // -> To block.timestamp
        uint last_payment; // Time units in seconds
        uint contract_started;
        uint contract_end;
        uint256 amount;
        rent_state state;
        uint extension;
        bool housing;
        uint surety;
    }

    uint public rent_count = 0;
    mapping(uint => Rent_t) rents;

    /* ------------- Events ------------- */
    
    event Surety_Paid(
        uint id_rent,
        uint amount,
        address landlord,
        address tenant
    );

    event Rent_Transfer (
        uint id_rent,
        address landlord,
        address tenant,
        uint amount
    );

    event Cancel_Rent(
        uint id_rent,
        address landlord, 
        address tenant,
        uint extension
    );

    event Contract_End(
        uint id_rent,
        address landlord,
        address tenant
    );

    event Offer_Accepted(
        address landlord,
        address tenant,
        uint frequency,
        uint amount
    );

    /* ---------------------------------- */

    /* ------------ Requires ------------ */

    modifier user_exists(address _address) {
        // Check if user is persona fisica or juridica, and see if it is not null
        require(
            (is_persona_fisica(_address) || is_persona_juridica(_address)) && _address != address(0),
            "User does not exist in database"
        );
        _;
    }

    modifier not_null_amount(uint amount) {
        // Not null amount
        require(
            amount > 0,
            "Amount must not be less than 0"
        );
        _;
    }

    modifier not_null_frequency(uint frequency) {
        require(
            frequency > 0,
            "Frequency must not be less than 0"
        );
        _;
    }

    modifier rent_exists(uint id_rent) {
        require(
            id_rent >= 0 && rents[id_rent].state == rent_state.started,
            "Rent must exist and it has to be started"
        );
        _;
    }

    modifier payment_frequency(uint last_payment, uint frequency) {  // El pagament s'ha de fer en el temps pactat
        // Check time between payments
        require(
            block.timestamp - last_payment >= frequency, // Tal i com està agafarà frequency en s
            "To early to realize payment"
        );
        _;
    }

    modifier is_tenant(address _address, uint id_rent) {
        require(
            _address == rents[id_rent].tenant,
            "This address is not the tenant of the rent"
        );
        _;
    }

    modifier is_landlord(address _address, uint id_rent) {
        require(
            _address == rents[id_rent].landlord,
            "This address is not the landlord of the rent"
        );
        _;
    }

    modifier valid_sender(address _address, uint id_rent) {
        require(
            _address == rents[id_rent].tenant || _address == rents[id_rent].landlord,
            "Sender is not in the contract"
        );
        _;
    }

    modifier valid_payment_request(uint id_rent) {
        require(
            block.timestamp - rents[id_rent].last_payment > rents[id_rent].frequency,
            "Payment has not expired"
        );
        _;
    }

    modifier rent_started(uint id_rent) {
        require(
            rents[id_rent].state == rent_state.started || rents[id_rent].state == rent_state.cancelled,            
            "Rent is not started"
        );
        _;
    }

    modifier rent_not_started(uint id_rent) {
        require(
            rents[id_rent].state == rent_state.not_started,
            "Rent is already started, or does not exist"
        );
        _;
    }
 
    /* ---------------------------------- */

    /* -------- Rent Contract Offers ---------- */

    function new_offer(bool _is_landlord, uint _amount, uint _frequency, uint _extension, uint _contract_duration, uint surety) public user_exists(msg.sender) {
        set_offer(_is_landlord, _amount, _frequency, _extension, _contract_duration, surety);
    }

    function pick_offer(uint offer_id) public user_exists(msg.sender) {
        accept_offer(offer_id, msg.sender);
    }

    function accept_rent_request(uint id_request) public {
        require(msg.sender == offers[requests[id_request].offer_id].user, "User is not the offerer");
        
        Offer memory offer = offers[requests[id_request].offer_id];
        RequestOffer memory request = requests[id_request];

        set_inactive(requests[id_request].offer_id); 

        if(offer.is_landlord) {
            create_rent(offer.user, request.requester, offer.frequency, block.timestamp + offer.contract_duration, offer.amount, offer.extension, request.housing, offer.surety);
            emit Offer_Accepted(offer.user, request.requester, offer.frequency, offer.amount);
        } else {
            create_rent(request.requester, offer.user, offer.frequency, block.timestamp + offer.contract_duration, offer.amount, offer.extension, request.housing, offer.surety);
            emit Offer_Accepted(request.requester, offer.user, offer.frequency, offer.amount);
        }   
    }

    /* --------- Contract functions ----------- */
    function create_rent(address _landlord, address _tenant, uint _frequency, uint _contract_end, uint _amount, uint _extension, bool _housing, uint _surety) private 
        user_exists(_landlord)
        user_exists(_tenant)
        not_null_amount(_amount) 
        not_null_frequency(_frequency)
    {
        // rents.push(Rent_t(rent_count, landlord, tenant, frequency, next_payment, contract_end, amount, rent_state.started, extension, vivenda));
        Rent_t memory aux_rent;

        aux_rent.landlord = _landlord;
        aux_rent.tenant = _tenant;
        aux_rent.frequency = _frequency;
        aux_rent.last_payment = 0;
        aux_rent.contract_started = 0;
        aux_rent.contract_end = _contract_end;
        aux_rent.amount = _amount;
        aux_rent.extension = _extension;
        aux_rent.housing = _housing;
        aux_rent.surety = _surety;

        aux_rent.state = rent_state.not_started; // Surety Needs to be paid

        rents[rent_count] = aux_rent;

        rent_count++;
    }

    function pay_surety(uint id_rent, string memory message) public 
        is_tenant(msg.sender, id_rent) 
        rent_not_started(id_rent)
    {        
        emit Surety_Paid(id_rent, rents[id_rent].amount, rents[id_rent].landlord, rents[id_rent].tenant);
        
        add_transfer(id_rent, rents[id_rent].surety, message);    

        rents[id_rent].state = rent_state.started;
    }

    function pay_rent(uint id_rent, string memory message) public
        payment_frequency(rents[id_rent].last_payment, rents[id_rent].frequency) 
        is_tenant(msg.sender, id_rent) 
        rent_started(id_rent)
    {                                                              // This function can only be executed by the tenant of the rent id_rent
        rents[id_rent].last_payment = block.timestamp; 
        // In this function the payment would be realized

        add_transfer(id_rent, rents[id_rent].amount, message);

        if (rents[id_rent].contract_end <= block.timestamp) {
            contract_end(id_rent);
        } 

        if(rents[id_rent].contract_started == 0) {
            rents[id_rent].contract_started = block.timestamp;
        }

        rent_paid(id_rent);
    }

    function cancel_rent(uint id_rent) public 
        valid_sender(msg.sender, id_rent) 
        rent_started(id_rent)
    {
        Rent_t memory aux_rent = rents[id_rent];

        emit Cancel_Rent(id_rent, aux_rent.landlord, aux_rent.tenant, aux_rent.extension);
        
        rents[id_rent].state = rent_state.cancelled;

        // Here we change the value of the end of the contract, which is going to be now + extension
        rents[id_rent].contract_end = 
        rents[id_rent].extension;
    }

    function contract_end(uint id_rent) internal 
        rent_started(id_rent)
    {
        Rent_t memory aux_rent = rents[id_rent];

        emit Contract_End(id_rent, aux_rent.landlord, aux_rent.tenant);

        rents[id_rent].state = rent_state.surety_pending;
    }

    function surety_back(uint id_rent, bool accept, string memory message) public
        is_landlord(msg.sender, id_rent)
    {
        return_surety(id_rent, rents[id_rent].amount, message, accept);

        rents[id_rent].state = rent_state.ended;
    }

    /* ------------- Up_Conditions ------------------- */
    
    function tenant_proposes(uint id_rent, address _address) view private returns(bool) {
        if (_address == rents[id_rent].landlord) {
            return false;
        } 
        else if (_address == rents[id_rent].tenant) {
            return true;
        }
        revert("No address in this contract");
    }

    function get_parameter(string memory p) pure private returns(update_comps) {
        if (keccak256(abi.encodePacked(p)) == keccak256(abi.encodePacked("frequency"))) {
            return(update_comps.frequency);
        } else if(keccak256(abi.encodePacked(p)) == keccak256(abi.encodePacked("amount"))) {
            return(update_comps.amount);
        } else if(keccak256(abi.encodePacked(p)) == keccak256(abi.encodePacked("contract end"))) {
            return(update_comps.contract_end);
        } else if(keccak256(abi.encodePacked(p)) == keccak256(abi.encodePacked("extension"))) {
            return(update_comps.extension);
        } 
        revert("Got bad parameter");
    }

    function set_request(uint id_rent, uint value, string memory p) public 
        rent_started(id_rent) 
        valid_sender(msg.sender, id_rent) 
    {   
        bool tenant = tenant_proposes(id_rent, msg.sender);

        if(tenant) {
            require(
                msg.sender == rents[id_rent].tenant,
                "User is not tenant. "
            );
        }
        else {
            require(
                msg.sender == rents[id_rent].landlord,
                "User is not landlord. "
            );
        }

        update_comps parameter = get_parameter(p);

        assign_request(id_rent, rents[id_rent].landlord, rents[id_rent].tenant, tenant, value, parameter);
    }

    function request_accepted(uint id_req) public rent_started(reqs[id_req].id_rent) {
        require(reqs[id_req].state != req_state.pending, "Cannot change a value that is applied");

        accept_request(id_req);
        
        if (reqs[id_req].parameter == update_comps.frequency) {
            rents[reqs[id_req].id_rent].frequency = reqs[id_req].value;
        }
        else if (reqs[id_req].parameter == update_comps.amount) {
            rents[reqs[id_req].id_rent].amount = reqs[id_req].value;
        }
        else if (reqs[id_req].parameter == update_comps.contract_end) {
            rents[reqs[id_req].id_rent].contract_end = reqs[id_req].value;
        }
        else if (reqs[id_req].parameter == update_comps.extension) {
            rents[reqs[id_req].id_rent].extension = reqs[id_req].value;
        }
        revert("No possible update");
    }

    function request_refused(uint id_req) public rent_started(reqs[id_req].id_rent) {
        refuse_request(id_req);
    }

    /* ------ Payment Request ------- */
    function create_payment_request(uint _id_rent) public 
        is_landlord(msg.sender, _id_rent)
        valid_payment_request(_id_rent)
    { // valid payment request means in time
        
        payment_reqs.push(Request_Payment(req_payment_count, _id_rent, payment_req_state.not_payed));

        req_payment_count++;
    }

    function rent_paid(uint _id_rent) public {  
        for (uint i = 0; payment_reqs.length < i; i++) {
            if (payment_reqs[i].id_rent == _id_rent && payment_reqs[i].state == payment_req_state.not_payed) {
                payment_reqs[i].state = payment_req_state.payed;
            }
        }
    }

    /* ----------- Transfers ---------- */
    function add_transfer(uint _id_rent, uint _amount, string memory _message) private is_tenant(msg.sender, _id_rent) {

        transfers.push(Transfer_t(_id_rent, _amount, _message));
        
        transfer_count++;
    }

    function return_surety(uint _id_rent, uint _amount, string memory _message, bool accept) private is_landlord(msg.sender, _id_rent) {
        // If accept is true, means that the property is in a good condition

        if(accept) {
            transfers.push(Transfer_t(_id_rent, _amount, _message));
        } else {
            transfers.push(Transfer_t(_id_rent, 0, _message));
        }
        transfer_count++;
    }

    /* ------ GETTERS ------ */
    function get_rent_state(uint id_rent) view public valid_sender(msg.sender, id_rent) returns(string memory) 
    {
        if(rents[id_rent].state == rent_state.not_started) {
            return("Not Started"); 
        } else if(rents[id_rent].state == rent_state.started) {
            return("Started"); 
        } else if(rents[id_rent].state == rent_state.cancelled) {
            return("Cancelled"); 
        } else if(rents[id_rent].state == rent_state.ended) {
            return("Ended"); 
        } else if(rents[id_rent].state == rent_state.surety_pending) {
            return("Surety Pending"); 
        } else {
            return("None");            
        } 
    }

    function get_rent(uint id_rent) view public returns(Rent_t memory) {
        require(id_rent < rent_count, "This rent does not exist. ");
        return(rents[id_rent]);
    }

    function get_pfisica(address _address, uint id_rent) view public returns(string memory, string memory, string memory, string memory) {  // X testeig es pública!!!!!!!!!!!!!
        require(
            msg.sender == _address || 
            (
                (rents[id_rent].tenant == _address && rents[id_rent].landlord == msg.sender) || 
                (rents[id_rent].landlord == _address && rents[id_rent].tenant == msg.sender) && 
                rents[id_rent].state != rent_state.ended 
            ));
        return(pfisiques[_address].dni, pfisiques[_address].nom, pfisiques[_address].adreca, pfisiques[_address].correu);
    }

    /* 
     * 
     *  Explicació de funcionament de la modularitat dels smart contracts inheritance
     *
     */

    // function get_fisiques() view public returns(address[] memory) {
    //     //Persona_Fisica pf = new Persona_Fisica();
    //     return get_pfisiques();
    // }

    // function pf(address _address) view public returns(bool) {
    //     return(pf.is_persona_fisica(_address));
    // }

    // function get_address() view public returns(address) {
    //     return(msg.sender);
    // }

    // function get_rent_addresses(uint id_rent) view public returns(address, address) {
    //     return(rents[id_rent].landlord, rents[id_rent].tenant);
    // }
}