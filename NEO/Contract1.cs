using Neo.SmartContract.Framework;
using Neo.SmartContract.Framework.Services.Neo;
using Neo.SmartContract.Framework.Services.System;
using System;
using System.ComponentModel;
using System.Numerics;

namespace NeoContract3
{
    public class Contract1 : SmartContract
    {

        [DisplayName("transfer")]
        public static event Action<byte[], byte[], BigInteger> Transferred;

        [DisplayName("refund")]
        public static event Action<byte[], BigInteger> Refund;

        [DisplayName("refundAsset")]
        public static event Action<byte[], byte[], BigInteger> RefundAsset;

        // byte[]sender, byte[] recipient, byte[] currency, biginteger amount
        [DisplayName("transferAsset")]
        public static event Action<byte[], byte[], byte[], BigInteger> TransferAsset;

        // byte[]sender, string orderType, byte[] orderAddress, byte[] fromCurrency, biginteger fromAmount, byte[] toCurrency, biginteger toAmount
        [DisplayName("createOrder")]
        public static event Action<byte[], string, byte[], byte[], BigInteger, byte[], BigInteger> CreateOrderLog;

        // byte[] orderAddress
        [DisplayName("cancelOrder")]
        public static event Action<byte[]> CancelOrderLog;

        // a lot of this code contains args
        //Especially the main function and the createorder function
        // args is an array of 7 objects (meaning they can be any data type)
        //
        //byte[] sender = (byte[])args[0];
        //      -the (byte[]) means it takes whatever args[0] is, and makes it into a byte array

        //byte[] fromCurrency = (byte[])args[1];  
        //      -what currency they have

        //BigInteger fromAmount = (BigInteger)args[2]; 
        //      -how much of that currency

        //byte[] toCurrency = (byte[])args[3];
        //      -what currency they want

        //BigInteger toAmount = (BigInteger)args[4];
        //      -what amount of currency they want

        //int belowNumner = (int)args[5];
        //      - what number they must roll under to win
        private static readonly byte[] AdminAccount = { 0 }; //this should be a byte array of the admin hash
        private static readonly byte[] NEO = { 155, 124, 255, 218, 166, 116, 190, 174, 15, 147, 14, 190, 96, 133, 175, 144, 147, 229, 254, 86, 179, 74, 92, 34, 12, 205, 207, 110, 252, 51, 111, 197 };//Neo currency byte array, this will be used in CurrencyDeposit and CurrencyWithdraw
        private static readonly byte[] GAS = { 155, 124, 255, 218, 166, 116, 190, 174, 15, 147, 14, 190, 96, 133, 175, 144, 147, 229, 254, 86, 179, 74, 92, 34, 12, 205, 207, 110, 252, 51, 111, 197 };//Gas currency byte array

        // Setup a NEP5 token that can be traded with no fee charged
        public static string Name() => "NeoBet Coin";
        public static string Symbol() => "NBET";
        public static byte Decimals() => 8;

        private const ulong factor = 100000000;
        private const ulong totalAmountNTC = 50000000 * factor;     // total supply of NTC tokens
        private const ulong icoBaseExchangeRate = 1000 * factor;    // number of tokens to trade per NEO during ico
        private const int icoDuration = 30;                         // number of days to run ico
        private const int icoDurationSeconds = icoDuration * 86400; // converts days to seconds
        private const int icoStartTimestamp = 1510753945; //time since 1970
        private const int icoEndTimestamp = icoStartTimestamp + icoDurationSeconds;

        // transaction fee charged on each order confirmation (not implemented in this version)
        private const float transactionFee = 0.25F;

        //Nothing is in main yet
        public static Object Main(string operation, params object[] args)
        {
            Runtime.Notify(" Main() operation", operation);

            if (Runtime.Trigger == TriggerType.Application)
            {
                Runtime.Notify("Main() Runtime.Application operation", operation);

            }
            else if (Runtime.Trigger == TriggerType.Verification)
            {
                Runtime.Notify("Main() TriggerType.Verification", TriggerType.Verification);
            }
            return false;
        }

        public static bool RequireArgumentLength(object[] args, int numArgs)
        {
            Runtime.Notify("RequireArgumentLength() required / received", numArgs, args.Length);
            return args.Length == numArgs;
        }

        //return a random number between 1 and 100 (hopefully, im not sure that hash encryptions are evenly 
        //distributed, I'll run some code on my test later, and ill report back with stats you can use
        //(and code you can publish) on the white paper to show the distributions.
        //if this doesnt distribute evenly we can just keep trying different encryptions until it does
        //average of all numbers from 0 to 99 is 4950
        private int GeneratePsRand()
        {
            uint height = Blockchain.GetHeight();
            byte[] blockHash = Blockchain.GetBlock(height).Hash;
            Header header = Blockchain.GetHeader(blockHash); //gets the block header by the hash
            ulong nonce = header.ConsensusData; //gets the pseudorandom nonce data
            return (int)(nonce % 99); //returns pseudorandom number from 0 to 99, as an integer
        }

        public static bool VerifyWitness(byte[] verifiedAddress)
        {
            bool isWitness = Runtime.CheckWitness(verifiedAddress);
            //Verifies that the calling contract has verified the required script hashes of the transaction
            //block, i.e.  is the admin hash
            Runtime.Notify("VerifyWitness() verifiedAddress", verifiedAddress);
            Runtime.Notify("VerifyWitness() isWitness", isWitness);
            //Notify's us of these things
            return isWitness;
        }

        public static bool VerifyOwnerAccount()
        {
            Runtime.Notify("VerifyOwnerAccount() Owner", GetAdminAccount());
            //notifies us
            return VerifyWitness(GetAdminAccount());
            //returns the ouput of the VerifyWitness function when it is fed the
            //byte array of the admin hash, and that output should be 
            //true if the admin hash is the same as the witnesses 
            //(i.e. the person using the smart contract is the admin, [i think])

            //Runtime.Notify("VerifyOwnerAccount() OwnerPubKey", OwnerPubKey);
            //byte[] signature = operation.AsByteArray();
            //bool sigVerify = VerifySignature(arg0, OwnerPubKey);
            //Runtime.Notify("Verification() sigVerify", sigVerify);
        }

        public static byte[] GetAdminAccount()
        {
            return AdminAccount;
            //Returns the byte array representing the Admin Account byte array
            //This is becuase the Admin Account is private, need a method to acsess
            //it if you want to use that array outside of this class
        }
        public static byte[] GetNeoCurrency()
        {
            return NEO;
        }
        public static byte[] getGasCurrency()
        {
            return GAS;
        }

        public static byte[] GetCurrencyIndexName(byte[] address, byte[] currency)
        {
            return address.Concat(currency);
            //Should combine (and then return) two arrays, but i can't find the documentation
            //If it doesnt work this maybe:
            /*
             *byte[] ret = new byte[address.Length + currency.Length];
             *Buffer.BlockCopy(first, 0, ret, 0, first.Length);
             *Buffer.BlockCopy(second, 0, ret, first.Length, second.Length);
             *return ret;
             */
        }

        //check to see if a user has a balance of a certain currency
        public static BigInteger GetBalanceOfCurrency(byte[] address, byte[] currency)
        {
            byte[] indexName = GetCurrencyIndexName(address, currency);
            Runtime.Notify("GetBalanceOfCurrency() indexName", indexName);

            BigInteger currentBalance = Storage.Get(Storage.CurrentContext, indexName).AsBigInteger();
            Runtime.Notify("GetBalanceOfCurrency() currency", currency);
            Runtime.Notify("GetBalanceOfCurrency() currentBalance", currentBalance);
            return currentBalance;
        }
        //user is requesting funds to be withdrawn rom contract
        public static bool WithdrawCurrency(byte[] destinationAddress, byte[] currency, BigInteger withdrawAmount)

        {
            if (!Runtime.CheckWitness(destinationAddress))
            {
                // ensure transaction is signed properly
                Runtime.Notify("WithdrawCurrency() CheckWitness failed", destinationAddress);

                return false;
            }

            Runtime.Notify("WithdrawCurrency() destinationAddress", destinationAddress);

            Runtime.Notify("WithdrawCurrency() currency", currency);
            Runtime.Notify("WithdrawCurrency() withdrawAmount", withdrawAmount);

            BigInteger currentBalance = GetBalanceOfCurrency(destinationAddress, currency);


            if (currentBalance <= 0 || currentBalance < withdrawAmount)
            {
                Runtime.Notify("WithdrawCurrency() insufficient funds", currentBalance);
                return false;
            }


            CurrencyWithdraw(destinationAddress, currency, withdrawAmount);
            return true;
        }

        public static void CurrencyWithdraw(byte[] address, byte[] currency, BigInteger takeFunds)
        {
            byte[] indexName = GetCurrencyIndexName(address, currency);
            //indexName is a byte array that is the concat of the two input byte arrays
            BigInteger currentBalance = GetBalanceOfCurrency(address, currency);
            Runtime.Notify("CurrencyWithdraw() indexName", indexName);
            //Notifys the client of indexName
            Runtime.Notify("CurrencyWithdraw() currentBalance", currentBalance);
            Runtime.Notify("CurrencyWithdraw() takeFunds", takeFunds);

            BigInteger updateBalance = currentBalance - takeFunds;
            // the value that will be stored in the persistant store of the
            // context with the currency/address concat key

            if (WithdrawCurrency(address, currency, takeFunds))
            {
                Runtime.Notify("CurrencyWithdraw() removing balance reference", updateBalance);
                Storage.Delete(Storage.CurrentContext, indexName);
                // deletes the current context
            }
            else
            {
                Runtime.Notify("CurrencyWithdraw() setting balance", updateBalance);
                Storage.Put(Storage.CurrentContext, indexName, updateBalance);
                // sets the current context to the updated balance
            }
        }


        public static void CurrencyDeposit(byte[] address, byte[] currency, BigInteger newFunds)
        {
            byte[] indexName = GetCurrencyIndexName(address, currency); //concats these
            BigInteger currentBalance = GetBalanceOfCurrency(address, currency); //same as above
            Runtime.Notify("CurrencyDeposit() indexName", indexName);
            Runtime.Notify("CurrencyDeposit() currentBalance", currentBalance);
            Runtime.Notify("CurrencyDeposit() newFunds", newFunds);

            BigInteger updateBalance = currentBalance + newFunds; //new value to store later

            if (updateBalance <= 0)
            {
                Runtime.Notify("CurrencyDeposit() removing balance reference", updateBalance);
                Storage.Delete(Storage.CurrentContext, indexName); //deletes if account is empty
            }
            else
            {
                Runtime.Notify("CurrencyDeposit() setting balance", updateBalance);
                Storage.Put(Storage.CurrentContext, indexName, updateBalance); //puts the updated balnce in
            }
        }

        // neo or gas is being deposited via invocation
        public static bool DepositAsset(object[] args)
        {
            Runtime.Notify("DepositAsset() args.Length", args.Length);

            Transaction tx = (Transaction)ExecutionEngine.ScriptContainer;
            TransactionOutput reference = tx.GetReferences()[0];

            if (reference.AssetId != NEO && reference.AssetId != GAS)
            {
                // transferred asset is not neo or gas, do nothing
                Runtime.Notify("DepositAsset() reference.AssetID is not NEO|GAS", reference.AssetId);
                return false;
            }

            TransactionOutput[] outputs = tx.GetOutputs();
            byte[] sender = reference.ScriptHash;                                   // the sender of funds, balance will be credited here
            byte[] receiver = ExecutionEngine.ExecutingScriptHash;                  // scriptHash of SC
            ulong receivedNEO = 0;
            ulong receivedGAS = 0;

            Runtime.Notify("DepositAsset() recipient of funds", ExecutionEngine.ExecutingScriptHash);

            // Calculate the total amount of NEO|GAS transferred to the smart contract address
            foreach (TransactionOutput output in outputs)
            {
                if (output.ScriptHash == receiver)
                {
                    // only add funds to total received value if receiver is the recipient of the output
                    ulong receivedValue = (ulong)output.Value;
                    Runtime.Notify("DepositAsset() Received Deposit type", reference.AssetId);
                    if (reference.AssetId == NEO)
                    {
                        Runtime.Notify("DepositAsset() adding NEO to total", receivedValue);
                        receivedNEO += receivedValue;
                    }
                    else if (reference.AssetId == GAS)
                    {
                        Runtime.Notify("DepositAsset() adding GAS to total", receivedValue);
                        receivedGAS += receivedValue;
                    }
                }
            }

            Runtime.Notify("DepositAsset() receivedNEO", receivedNEO);
            Runtime.Notify("DepositAsset() receivedGAS", receivedGAS);

            if (receivedNEO > 0)
            {
                CurrencyDeposit(sender, NEO, receivedNEO);
                TransferAsset(null, sender, NEO, receivedNEO);
            }

            if (receivedGAS > 0)
            {
                CurrencyDeposit(sender, GAS, receivedGAS);
                TransferAsset(null, sender, GAS, receivedGAS);
            }

            return true;
        }

        //set the balance of an NEP5 token for a user
        public static bool SetBalanceOfNEP5Currency(byte[] address, string currency, BigInteger newFunds)
        {
            if (!VerifyOwnerAccount())
            {
                // only the contract owner can set the balance of nep5 tokens
                Runtime.Notify("SetBalanceOfNEP5Currency() VerifyOwnerAccount failed", false);
                return false;
            }

            Runtime.Notify("SetBalanceOfNEP5Currency() calling CurrencyDeposit()", address);
            CurrencyDeposit(address, currency.AsByteArray(), newFunds);
            return true;
        }
        //This is for Creating and Using NeoBet Tokens
        //////////////////////////////////////////////////////////////////////////////////////////
        // BEGIN NEP5 implementation

        //create tokens upon receipt of neo
        public static bool MintTokens()
        {
            Transaction tx = (Transaction)ExecutionEngine.ScriptContainer;
            TransactionOutput reference = tx.GetReferences()[0];
            if (reference.AssetId != NEO)
            {
                // transferred asset is not neo, do nothing
                Runtime.Notify("MintTokens() reference.AssetID is not NEO", reference.AssetId);
                return false;
            }

            byte[] sender = reference.ScriptHash;
            TransactionOutput[] outputs = tx.GetOutputs();
            byte[] receiver = ExecutionEngine.ExecutingScriptHash;
            ulong receivedNEO = 0;
            Runtime.Notify("DepositAsset() recipient of funds", ExecutionEngine.ExecutingScriptHash);

            // Gets the total amount of Neo transferred to the smart contract address
            foreach (TransactionOutput output in outputs)
            {
                if (output.ScriptHash == receiver)
                {
                    receivedNEO += (ulong)output.Value;
                }
            }

            Runtime.Notify("MintTokens() receivedNEO", receivedNEO);

            if (receivedNEO <= 0)
            {
                Runtime.Log("MintTokens() receivedNEO was <= 0");
                return false;
            }

            ulong exchangeRate = CurrentSwapRate();
            Runtime.Notify("MintTokens() exchangeRate", exchangeRate);

            if (exchangeRate == 0)
            {
                // ico has ended, or the token supply is exhausted
                Refund(sender, receivedNEO);
                Runtime.Log("MintTokens() exchangeRate was == 0");

                return false;
            }

            ulong numMintedTokens = receivedNEO * exchangeRate / 100000000; //this is for divisible tokens i think

            Runtime.Notify("MintTokens() receivedNEO", receivedNEO);
            Runtime.Notify("MintTokens() numMintedTokens", numMintedTokens);

            SetBalanceOf(sender, BalanceOf(sender) + numMintedTokens);
            SetTotalSupply(numMintedTokens);
            Transferred(null, sender, numMintedTokens);
            return true;
        }

        //set the total supply value
        private static void SetTotalSupply(ulong newlyMintedTokens)
        {
            BigInteger currentTotalSupply = TotalSupply();
            Runtime.Notify("SetTotalSupply() newlyMintedTokens", newlyMintedTokens);
            Runtime.Notify("SetTotalSupply() currentTotalSupply", currentTotalSupply);
            Runtime.Notify("SetTotalSupply() newlyMintedTokens + currentTotalSupply", newlyMintedTokens + currentTotalSupply);

            Storage.Put(Storage.CurrentContext, "totalSupply", currentTotalSupply + newlyMintedTokens);
        }

        //how many tokens have been issued
        public static BigInteger TotalSupply()
        {
            return Storage.Get(Storage.CurrentContext, "totalSupply").AsBigInteger();
        }

        //transfer value between from and to accounts
        public static bool Transfer(byte[] from, byte[] to, BigInteger transferValue)
        {
            Runtime.Notify("Transfer() transferValue", transferValue);
            if (transferValue <= 0)
            {
                // don't accept stupid values
                Runtime.Notify("Transfer() transferValue was <= 0", transferValue);
                return false;
            }
            if (!Runtime.CheckWitness(from))
            {
                // ensure transaction is signed properly
                Runtime.Notify("Transfer() CheckWitness failed", from);
                return false;
            }
            if (from == to)
            {
                // don't waste resources when from==to
                Runtime.Notify("Transfer() from == to failed", to);
                return true;
            }
            BigInteger fromBalance = BalanceOf(from);                   // retrieve balance of originating account
            if (fromBalance < transferValue)
            {
                Runtime.Notify("Transfer() fromBalance < transferValue", fromBalance);
                // don't transfer if funds not available
                return false;
            }

            SetBalanceOf(from, fromBalance - transferValue);            // remove balance from originating account
            SetBalanceOf(to, BalanceOf(to) + transferValue);            // set new balance for destination account

            Transferred(from, to, transferValue);
            return true;
        }

        //set newBalance for address
        private static void SetBalanceOf(byte[] address, BigInteger newBalance)
        {
            if (newBalance <= 0)
            {
                Runtime.Notify("SetBalanceOf() removing balance reference", newBalance);
                Storage.Delete(Storage.CurrentContext, address);
            }
            else
            {
                Runtime.Notify("SetBalanceOf() setting balance", newBalance);
                Storage.Put(Storage.CurrentContext, address, newBalance);
            }
        }

        //retrieve the number of tokens stored in address
        public static BigInteger BalanceOf(byte[] address)
        {
            BigInteger currentBalance = Storage.Get(Storage.CurrentContext, address).AsBigInteger();
            Runtime.Notify("BalanceOf() currentBalance", currentBalance);
            return currentBalance;
        }

        //determine whether or not the ico is still running and provide a bonus rate for the first 3 weeks
        private static ulong CurrentSwapRate()
        {
            if (TotalSupply() >= totalAmountNTC)
            {
                // supply has been exhausted
                return 0;
            }

            uint currentTimestamp = Blockchain.GetHeader(Blockchain.GetHeight()).Timestamp;
            int timeRunning = (int)currentTimestamp - icoStartTimestamp;
            Runtime.Notify("CurrentSwapRate() timeRunning", timeRunning);

            if (currentTimestamp > icoEndTimestamp || timeRunning < 0)
            {
                // ico period has not started or is ended
                return 0;
            }

            ulong bonusRate = 0;

            if (timeRunning < 604800)
            {
                // first week gives 30% bonus
                bonusRate = 30;
            }
            else if (timeRunning < 1209600)
            {
                // second week gives 20% bonus
                bonusRate = 20;
            }
            else if (timeRunning < 1814400)
            {
                // third week gives 10% bonus
                bonusRate = 10;
            }

            ulong swapRate = (icoBaseExchangeRate * (100 + bonusRate)) / 100;

            Runtime.Notify("CurrentSwapRate() bonusRate", bonusRate);
            Runtime.Notify("CurrentSwapRate() swapRate", swapRate);
            return swapRate;
        }

    }
}
