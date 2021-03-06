import 'package:butter_app/models/user.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'database_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  //create user obj based onn firebase user
  User _userFromFirebaseUser(FirebaseUser user) {
    return user == null ? null : User(uid: user.uid);
  }

  //auth chnages for user stream
  Stream<User> get user {
    return _auth.onAuthStateChanged.map(_userFromFirebaseUser);
  }

  //sign in anon
  Future signInAnon() async {
    try {
      AuthResult result = await _auth.signInAnonymously();
      FirebaseUser user = result.user;
      return user;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  //signin mail
  Future signInWithEmailAndPassword(String email, String password) async {
    try {
      AuthResult result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      FirebaseUser user = result.user;

      return _userFromFirebaseUser(user);
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  //register
  Future registerWithEmailAndPassword(
      String name,
      String age,
      String photoUrl,
      String cakeDay,
      String nickname,
      String phoneNumber,
      String country,
      String email,
      String password) async {
    try {
      AuthResult result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      FirebaseUser user = result.user;
      await DatabaseService(uid: user.uid).createUserData(
          name, age, photoUrl, cakeDay, nickname, phoneNumber, country);
      await DatabaseService(uid: user.uid).updatePoints(0, 0);
      await DatabaseService(uid: user.uid).updateLocation(user.uid, null);
      return _userFromFirebaseUser(user);
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  //signout
  Future signOut() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
      return true;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  //google sign in
  Future googleSignIn() async {
    FirebaseUser currentUser;
    try {
      final GoogleSignInAccount googleUser = await _googleSignIn.signIn();
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.getCredential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final FirebaseUser user =
          (await _auth.signInWithCredential(credential)).user;
      assert(user.email != null);
      assert(user.displayName != null);
      assert(!user.isAnonymous);
      assert(await user.getIdToken() != null);
      currentUser = await _auth.currentUser();
      assert(user.uid == currentUser.uid);
      String name = user.displayName;
      String nickname = "ButterUser";
      String photoUrl = "";
      if (user.photoUrl != null) photoUrl = user.photoUrl;
      String age = "18";
      String country = "None";
      String phoneNumber = "";
      String cakeDay = DateTime.now().toString();
      if (user.phoneNumber != null) phoneNumber = user.phoneNumber;
      if (await DatabaseService(uid: currentUser.uid).checkUserExist()) {
        await DatabaseService(uid: currentUser.uid).createUserData(
            name, age, photoUrl, cakeDay, nickname, phoneNumber, country);
        print("entered");
        await DatabaseService(uid: user.uid).updatePoints(0, 0);
        await DatabaseService(uid: user.uid).updateLocation(user.uid, null);
      }
      return _userFromFirebaseUser(currentUser);
    } catch (e) {
      print("google sign in excepton" + e.toString());
      return null;
    }
  }
}
