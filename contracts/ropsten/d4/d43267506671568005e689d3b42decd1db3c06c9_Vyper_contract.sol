# @version ^0.3.1
# Invoice smart contract for Crypto Ninja

# constants
STATUS_UNPAID: constant(uint8) = 0
STATUS_PARTIALLY_PAID: constant(uint8) = 1
STATUS_FULLY_PAID: constant(uint8) = 2
CURRENCY_LENGTH: constant(uint256) = 20

# the Invoice object
invoice_id: uint256 # human readable invoice ID
status: uint8
# TODO: verify max length of currency.
currency: String[CURRENCY_LENGTH] # destination currency
amount_due: uint256 # amount_due in currency units.
amount_received: uint256 # amount_received from consumer
rate: decimal # exchange rate from wei to USD.
send_to: address

event Payment:
	sender: address
	invoice_id: uint256
	invoice_address: address
	amount_accepted: uint256
	amount_returned: uint256

@external
def setup(
	_invoice_id: uint256,
	_currency: String[CURRENCY_LENGTH],
	_amount_due: uint256,
	_rate: decimal,
	_send_to: address,
):
	'''
	Construct a new invoice contract instance.

	:param _invoice_id: The invoice number, which must be unique
		for each merchant.
	:param _currency: The crypto-currency symbol, which the invoice
		will be paid in.
	:param _amount_due: The total amount due on the invoice.
	:param _rate: The exchange rate, used to calculate if the
		invoice if fully paid.
	:param _send_to: The address to send _amount_due to after
		the invoice is fully paid.
	'''
	assert _invoice_id > 0
	assert len(_currency) > 0
	assert _amount_due > 0
	assert _rate > 0.0
	assert _send_to != ZERO_ADDRESS
	self.invoice_id = _invoice_id
	self.status = STATUS_UNPAID
	self.currency = _currency
	self.amount_due = _amount_due
	self.rate = _rate
	self.send_to = _send_to

@external
@payable
def __default__():
	overpayment: uint256 = 0
	amount_accepted: uint256 = 0
	status: uint8 = self.status
	total_received: uint256 = self.amount_received + msg.value
	if total_received < self.amount_due:
		# partial payment recieved
		amount_accepted = msg.value
		status = STATUS_PARTIALLY_PAID
	elif total_received == self.amount_due:
		# full payment received
		amount_accepted = msg.value
		status = STATUS_FULLY_PAID
	else:
		# overpayment recieved
		overpayment = total_received - self.amount_due
		amount_accepted = msg.value - overpayment
		status = STATUS_FULLY_PAID

	# send amount_accepted to Crypto Ninja for routing to exchange
	send(self.send_to, amount_accepted)

	# update Invoice attributes on the blockchain
	self.amount_received = self.amount_received + amount_accepted
	self.status = status

	# process refund of overpayment
	if overpayment > 0:
		send(tx.origin, overpayment)

	# notify client of payment
	log	Payment(
		tx.origin,
		self.invoice_id,
		self,
		amount_accepted,
		overpayment,
	)