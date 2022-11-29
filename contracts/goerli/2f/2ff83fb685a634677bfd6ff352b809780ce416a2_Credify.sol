pragma solidity 0.8.6;


/*

	Entity Involved:
       		* Payer
	       	* Payee 
	
	Flow:
		* Payee creates a Request to Payer by giving params like (amount, timePeriod, token)
			* Amount = it is the amount of the token
				that Payee wants of the token
			* timePeriod = it is the re-occuring time period, for ex: the payee will be 
				able to charge payer every month
			* token = this is the token address of the token that payee wants
		
 		* Payer sees this request and can choose to approve or deny it 
		
 		* If accepted the Payee will be able to call `charge` function and get their amount from the Payer

*/
contract Enum {
    enum Operation {Call, DelegateCall}
}
interface GnosisSafe{
	function execTransactionFromModuleReturnData(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation
	) external virtual returns (bool success, bytes memory returnData);
}

// @title Credit Card for crypto
contract Credify{
	struct Request{
		address reciever;
		uint256 timePeriod;
		uint256 amount;
		address token;
		string name;
		uint256 lastPayment;
		address payer;
		bool approved;
		bool isNew;
	}

	mapping(address => Request[]) public credits;
	mapping(bytes32 => Request) public requests;

	// @notice Emitted When a Entity wants the Payer to subscribe to their service
	// @param reciever The address of the enitity recieving payment
	// @parram timePeriod The time period between succssive payments
	// @param amount The amount that, payee wants
	// @param name The name of the enitity Requesting Payment
	event RequestSubscribtion(
		address reciever,
		uint256 timePeriod,
		uint256 amount,
		string name
	);

	// @notice Emitted When the Payer accepts the Payee Request to subscribe to their service
	// @param reciever The address of the enitity recieving payment
	// @parram timePeriod The time period between succssive payments
	// @param amount The amount that, payee wants
	// @param name The name of the enitity Requesting Payment
	event Subscribe(
		address reciever,
		uint256 timePeriod,
		uint256 amount,
		string name
	);

	// @notice Emitted When the Payer Unsubscribe from the Payee services
	// @param reciever The address of the enitity recieving payment
	// @parram timePeriod The time period between succssive payments
	// @param amount The amount that, payee wants
	// @param name The name of the enitity Requesting Payment
	event UnSubscribe(
		address reciever,
		uint256 timePeriod,
		uint256 amount,
		string name
	);


	constructor() {
		
	}

	function createRequest(
		address payer,
		address reciever,
		uint256 timePeriod,
		uint256 amount, 
		address token,
		string memory name
	) public returns(bytes32 id){ 
		uint256 nounce = credits[reciever].length;
		bytes32 id = getId(reciever, timePeriod, amount, name, payer, nounce);

		credits[reciever].push(Request(
			reciever,
			timePeriod,
			amount,
			token,
			name,
			0,
			payer,
			false,
			true
		));


		emit RequestSubscribtion(
			reciever,
			timePeriod,
			amount,
			name
		);
	}

	function getPayment(bytes32 id) public{
		
		/*
			Get the Subscribtion data from the id
			Then check on basis of previous payemnt timstamp that if the payment is legit
			Then call the token transfer function 
		 */
		Request memory request = requests[id];
		require(isAuthorized(id), "Not Authorized");
		require(
			request.lastPayment==0 || 
			request.lastPayment - request.timePeriod >= request.timePeriod,
			"Can't Charge Out of time"
		);

		GnosisSafe(request.payer).execTransactionFromModuleReturnData(
			request.token,
			0,
			abi.encodeWithSelector(bytes4(keccak256("transfer(address,uint256)")), request.reciever, request.amount),
			Enum.Operation.Call
		);

		requests[id].lastPayment = block.timestamp;

	}

	function acceptRequest(bytes32 id) public {
		Request memory request = requests[id];
		require(request.payer == msg.sender, "Only Payer can Authorize Transaction");
		requests[id].approved = true;
		requests[id].isNew = false;
	}

	function cancelRequest(bytes32 id) public {
		Request memory request = requests[id];
		require(request.payer == msg.sender, "Only Payer can Authorize Transaction");
		requests[id].approved = false;
		
		emit UnSubscribe(
			request.reciever,
			request.timePeriod,
			request.amount,
			request.name
		);
	}

	function isAuthorized(bytes32 id) public view returns(bool isAllowed){
		isAllowed = requests[id].approved;
	}

	function getId(
		address reciever,
		uint256 timePeriod,
		uint256 amount, 
		string memory name,
		address payer,
		uint256 nounce
    ) public pure returns (bytes32) {
        return keccak256(abi.encode(
			reciever, 
			timePeriod, 
			amount, 
			name,
			payer,
			nounce
		));
    }
}