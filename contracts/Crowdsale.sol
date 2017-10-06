pragma solidity ^0.4.13;

contract token {
  function transfer(address receiver, uint amount);
}

contract Crowdsale {

  enum State {
    Open,
    Closed,
    TokensSoldOut,
    Payed // Total raised transfered to beneficiary
  }

  State public state = State.Open;

  struct Contribution {
    uint amount;
    address contributor;
  }

  Contribution[] contributions;

  uint public totalRaisedInWei;
  uint public totalSdsUnits; // 1 Sds = 1000000000000000000 units (18 zeros)
  uint public availableSdsUnits;
  uint public deadline; // timestamp
  uint public completedAt; // timestamp
  uint public priceOfUnitInWei; // Price of 1 Sds unit in WEI. 1 ETH = 1000000000000000000 WEI (18 zeros)
  address public creator;
  address public beneficiary; // Can be wallet
  string public campaignUrl;

  token public sdsToken; // Address that holds the smart contract of the token

  event LogFundingReceived(address addr, uint amount, uint currentTotal);
  event LogBeneficiaryPaid(address beneficiary);
  event LogFundingSuccessful(uint totalRaisedInWei);
  event LogFunderInitialized(address creator, address beneficiary, string url, uint deadline);

  modifier inState(State _state) {
    require(state == _state);
    _;
  }

  modifier isCreator() {
    require(msg.sender == creator);
    _;
  }

  // Run only at least 1 hour after funding is completed
  modifier atEndOfLifeCycle() {
    require(state == State.Closed && completedAt + 1 hours < now);
    _;
  }

  function Crowdsale(
    uint _timeInMinutesForFundraising,
    string _campaignUrl,
    address _beneficiary, // Beneficiary address
    token _addressOfSdsToken, // Token used as a reward
    uint _priceOfUnitInWei,
    uint _totalSdsUnits
  ) {

    creator = msg.sender;
    beneficiary = _beneficiary;
    campaignUrl = _campaignUrl;
    deadline = now + (_timeInMinutesForFundraising * 1 minutes);
    totalRaisedInWei = 0;
    totalSdsUnits = _totalSdsUnits;
    availableSdsUnits = _totalSdsUnits;
    sdsToken = token(_addressOfSdsToken);
    priceOfUnitInWei = _priceOfUnitInWei;

    LogFunderInitialized(creator, beneficiary, campaignUrl, deadline);
  }

  function () payable {

    require(state == State.Open);
    require(now <= deadline);

    uint amountInWei = msg.value;
    uint sdsUnitsRequested = amountInWei / priceOfUnitInWei;

    require(availableSdsUnits >= sdsUnitsRequested);

    contributions.push(Contribution({ amount: msg.value, contributor: msg.sender }));
    totalRaisedInWei += msg.value;

    sdsToken.transfer(msg.sender, sdsUnitsRequested);
    availableSdsUnits -= sdsUnitsRequested;

    LogFundingReceived(msg.sender, msg.value, totalRaisedInWei);

    checkStatus();
  }

  function checkStatus() {
    if (availableSdsUnits == 0) {
      state = State.TokensSoldOut;
      LogFundingSuccessful(totalRaisedInWei);
      completedAt = now;
    }
  }

  function closeAndPayout()
    public
    isCreator()
  {
    require(now > deadline || state == State.TokensSoldOut);

    LogFundingSuccessful(totalRaisedInWei);
    state = State.Closed;

    require(beneficiary.send(this.balance));
    LogBeneficiaryPaid(beneficiary);
  }

  function removeContract()
    public
    isCreator()
    atEndOfLifeCycle()
  {
    selfdestruct(msg.sender);
  }
}
