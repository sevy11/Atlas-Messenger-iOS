//
//  LYRKeyPair.h
//  LayerKit
//
//  Created by Blake Watters on 3/25/14.
//  Copyright (c) 2014 Layer Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

/// The domain for error generated by the Security Framework and wrapped into `NSError` objects. Emitted by `LYRKeyPair` methods.
extern NSString *const LYRSecurityErrorDomain;

/**
 The `LYRKeyPair` class provides a convenient interface for the generation and utilization
 of a cryptographic key pair.
 
 Signatures are generated and verified using SHA256 with PKCS1 padding.
 */
@interface LYRKeyPair : NSObject

///----------------------------
/// @name Generating a Key Pair
///----------------------------

/**
 Generates a new key pair with the given identifier.
 
 @param identifier A string used to uniquely identify the key pair within the keychain.
 @param bits The desires size of the cryptographic key-pair in bits. A value of 2048 is recommended.
 @param error A pointer to an error object that, upon failure, is set to an error object describing the nature of the failure.
 @return A newly created key pair object.
 */
+ (instancetype)generateKeyPairWithIdentifier:(NSString *)identifier size:(NSUInteger)bits error:(NSError **)error;

/**
 @abstract The identifier for the keypair. Used to uniquely identify it within the Keychain.
 @discussion An `identifier` of `nil` indicates that the receiver has not been persisted to the keychain.
 */
@property (nonatomic, copy, readonly) NSString *identifier;

/**
 The Keychain reference for the public key.
 */
@property (nonatomic, assign, readonly) SecKeyRef publicKeyRef;

/**
 The public key data.
 */
@property (nonatomic, readonly) NSData *publicKeyData;

/**
 The private key data.
 */
@property (nonatomic, readonly) NSData *privateKeyData;

/**
 The Keychain reference for the public key.
 */
@property (nonatomic, assign, readonly) SecKeyRef privateKeyRef;

/**
 The size of the keys in the assymmetric key pair, in bits.
 */
@property (nonatomic, assign, readonly) NSUInteger keySizeInBits;

///----------------------------------------------
/// @name Retrieving a Key Pair from the Keychain
///----------------------------------------------

/**
 Retrieves an existing key pair from the keychain with the given identifier.
 
 @param identifier A string used to uniquely identify the key pair within the keychain.
 @param error A pointer to an error object that, upon failure, is set to an error object describing the nature of the failure.
 @return A keypair object retrieved from the keychain with the given identifier.
 */
+ (instancetype)keyPairWithIdentifier:(NSString *)identifier error:(NSError **)error;

///--------------------------------------------
/// @name Initializing a Key Pair from Key Data
///--------------------------------------------

+ (instancetype)keyPairWithIdentifier:(NSString *)identifier privateKeyData:(NSData *)privateKeyData publicKeyData:(NSData *)publicKeyData size:(NSUInteger)bits;

/**
 @abstract Returns a Boolean value that indicates if the key pair modeled by the receiver is in the Keychain.
 @return `YES` if the key pair exists in the Keychain, else `NO`.
 */
- (BOOL)existsInKeychain;

/**
 @abstract Saves the keypair to the Keychain.
 
 @param error A pointer to an error object that upon failure describes the nature of the error.
 @return A Boolean value indicating if persistence to the Keychain was successful.
 */
- (BOOL)saveToKeychain:(NSError **)error;

///-----------------------------------
/// @name Encrypting & Decrypting Data
///-----------------------------------

/**
 @abstract Encrypts the input data using the keys modeled by the receiver.
 
 @param data The plaintext data to be encrypted.
 @param error A pointer to an error object that, upon failure, is set to an error object describing the nature of the failure.
 @return The encrypted data or `nil` if the encryption operation fails.
 */
- (NSData *)dataByEncryptingData:(NSData *)data error:(NSError **)error;

/**
 @abstract Decrypts the input data using the keys modeled by the receiver.
 
 @param data The encrypted data to be decrypted.
 @param error A pointer to an error object that, upon failure, is set to an error object describing the nature of the failure.
 @return The decrypted data or `nil` if the decryption operation fails.
 */
- (NSData *)dataByDecryptingData:(NSData *)data error:(NSError **)error;

///-------------------------------------
/// @name Signing & Verifying Signatures
///-------------------------------------

/**
 @abstract Generates a cryptographic signature for the input data using the private key of the receiver. The signature is generated by computing
 a SHA256 digest of the input value and then generating a signature across the digest. The final signature value is encoded using
 PKCS1 padding.
 
 @param data The data to compute a signature for.
 @param error A pointer to an error object that, upon failure, is set to an error object describing the nature of the failure.
 @return The signature for the input data or `nil` if the signing operation fails.
 */
- (NSData *)signatureForData:(NSData *)data error:(NSError *__autoreleasing *)error;

/**
 @abstract Validates a cryptographic signature using the public key of the receiver. The signature is assumed be a PKCS1-style signature with DER
 encoding of a SHA256 of the actual data.
 
 @param signature The cryptographic signature to be verified.
 @param data The source data that is being evaluated against the signature.
 @param error A pointer to an error object that, upon failure, is set to an error object describing the nature of the failure.
 @return A Boolean value that indicates if the signature matches the input data.
 */
- (BOOL)verifySignature:(NSData *)signature forData:(NSData *)data error:(NSError *__autoreleasing *)error;

@end