pragma solidity ^0.4.16;

contract token {
  function transfer(address receiver, uint amount);
  function mintToken(address target, uint mintedAmount);
}

contract Crowdsale {

  enum State {
    Fundraising, // Initial state
    Failed, // Failed reaching the minimum target
    Successful, // Completed but not transfered the fund to the funders
    Closed // All completed
  }

  State public state = State.Fundraising;

  struct Contribution {
    uint amount;
    address contributor;
  }

  Contribution[] contributions;

  uint public totalRaised;
  uint public currentBalance;
  uint public deadline; // timestamp
  uint public completedAt; // timestamp
  uint public priceInWei; // Price of the token in WEI (smallest unit of Eth) 1 ETH = 1000000000000000000 WEI (18 zeros)
  uint public fundingMinimumTargetInWei;
  uint public fundingMaximumTargetInWei;
  address public creator;
  address public beneficiary; // Can be a DAO or creator
  string public campaignUrl;
  byte constant version = "1";

  token public tokenReward; // Address that holds the smart contract of the token

  event LogFundingReceived(address addr, uint amount, uint currentTotal);
  event LogBeneficiaryPaid(address beneficiary);
  event LogFundingSuccessful(uint totalRaised);
  event LogFunderInitialized(address creator, address beneficiary, string url, uint _fundingMaximumTargetInEther, uint deadline);

  modifier inState(State _state) {
    require(state == _state);
    _;
  }

  // This is for tokens that cannot be devided into multiple pieces
  modifier isMinimum() {
    require(msg.value > priceInWei); // The transfered amount has to be higher than min price for one token
    _;
  }

  // This is for tokens that cannot be devided into multiple pieces
  modifier inMultipleOfPrice() {
    require(msg.value % priceInWei == 0); // The transfered amount has to be multiple of the price for one token
    _;
  }

  modifier isCreator() {
    require(msg.sender == creator);
    _;
  }

  // Run only at least 1 hour after funding is completed
  modifier atEndOfLifeCycle() {
    require((state == State.Failed || state == State.Successful) && completedAt + 1 hours < now);
    _;
  }

  function Crowdsale(
    uint _timeInMinutesForFundraising,
    string _campaignUrl,
    address _ifSuccessfulSendTo, // Beneficiary
    uint _fundingMaximumTargetInEther, // Set to 0 if no maximum - i.e. unlimited funding
    uint _fundingMinimumTargetInEther,
    token _addressOfToken, // Token used as a reward
    uint _costOfEachTokenInWei
  ) {

    creator = msg.sender;
    beneficiary = _ifSuccessfulSendTo;
    campaignUrl = _campaignUrl;
    fundingMaximumTargetInWei = _fundingMaximumTargetInEther * 1 ether;
    fundingMinimumTargetInWei = _fundingMinimumTargetInEther * 1 ether;
    deadline = now + (_timeInMinutesForFundraising * 1 minutes);
    currentBalance = 0;
    totalRaised = 0;
    tokenReward = token(_addressOfToken);
    priceInWei = _costOfEachTokenInWei;

    LogFunderInitialized(creator, beneficiary, campaignUrl, fundingMinimumTargetInWei, deadline);
  }

  function contribute()
    public
    inState(State.Fundraising)
    payable // payble ensures that a function can be used to contribute Ether to the smart contract
    returns (uint)
  {

    uint amountInWei = msg.value;
    contributions.push(Contribution({ amount: msg.value, contributor: msg.sender}));
    totalRaised += msg.value;
    currentBalance = totalRaised;

    if (fundingMaximumTargetInWei != 0) {
      // Limited funding - upper cap
      tokenReward.transfer(msg.sender, amountInWei / priceInWei);
    } else {
      // Unlimited funding
      tokenReward.mintToken(msg.sender, amountInWei / priceInWei);
    }

    LogFundingReceived(msg.sender, msg.value, totalRaised);

    checkIfFundingCompletedOrExpired();

    return contributions.length - 1;
  }

  function checkIfFundingCompletedOrExpired() {

    if (fundingMaximumTargetInWei != 0 && totalRaised > fundingMaximumTargetInWei) { // There was a target and it has been achieved
      state = State.Successful;
      LogFundingSuccessful(totalRaised);

      payout();
      completedAt = now;
    } else if (now > deadline) { // There was no target and deadline is expired

      if (totalRaised >= fundingMinimumTargetInWei) { // Min target achieved
        state = State.Successful;
        LogFundingSuccessful(totalRaised);

        payout();
        completedAt = now;
      } else { // Min target not achieved
        state = State.Failed;
        completedAt = now;
      }
    }
  }

  function payout()
    public
    inState(State.Successful)
  {
    require(beneficiary.send(this.balance));

    state = State.Closed;
    currentBalance = 0;
    LogBeneficiaryPaid(beneficiary);
  }

  function getRefund()
    public
    inState(State.Failed)
    returns (bool)
  {
    for (uint i = 0; i <= contributions.length; i++) {
      if (contributions[i].contributor == msg.sender) {
        uint amountToRefund = contributions[i].amount;
        contributions[i].amount = 0;

        if (!contributions[i].contributor.send(amountToRefund)) {
          // Send failed
          contributions[i].amount = amountToRefund;
          return false;
        } else {
          totalRaised -= amountToRefund;
          currentBalance = totalRaised;
          return true;
        }
      }
    }
    return false; // Sender not found
  }

  function removeContract()
    public
    isCreator()
    atEndOfLifeCycle()
  {
    selfdestruct(msg.sender);
  }

  function () { revert(); }
}
