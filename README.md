### Create a User:

Send `POST` to `/users` with this information:

```javascript
{
  "user": {
    "first_name": "FirstName",
    "last_name": "LastName",
    "username": "Username",
    "email": "test@example.com",
    "password": "anewpassword",
    "password_confirmation": "anewpassword"
  }
}
```

### Confirm a User:

Once a user is created they will receive a token via email.
All they have to do is click the link to activate their account.

### Login as a User:

To log in send a `POST` to `/users/auth` with a Basic Authorization header. The encoding is a string with this format "email:password":

```javascript
Authorization: Basic Z2xlbi5rZWxlckByb2RyaWd1ZXpyb2JlbC5pbmZvOlV5VnQ3clRjUA==
```

If authentication succeeds you will receive a response with an auth token similar to this:

```javascript
{
  "auth_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjoxLCJleHAiOjE0NzUzMTM5OTQsImlzcyI6Imlzc3Vlcl9uYW1lIiwiYXVkIjoiY2xpZW50In0.5P3qJKelCdbTixnLyIrsLKSVnRLCv2lvHFpXqVKdPOs"
}
```

Save this token in the application connecting to the api. You'll need it to authenticate future requests.


### Sending requests

Regardless of whether you are sending `GET`, `POST`, `PUT`, etc. requests make sure you send the saved JWT auth_token as a header.

The key needs to be `Authorization` and the value is:

```text
Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjoxLCJleHAiOjE0NzUzMTM5OTQsImlzcyI6Imlzc3Vlcl9uYW1lIiwiYXVkIjoiY2xpZW50In0.5P3qJKelCdbTixnLyIrsLKSVnRLCv2lvHFpXqVKdPOs
```


### Accessing params

Let's say you want to send some text with a request and you want the controller to do something with it. For example, you send this:

```javascript
{
  "note": "Here is my note."
}
```

If you want this information in the controller all you need to do is look for `params[:note]`. This will give you the note string value granted you pass authentication.


### Accessing JWT user

If you need to know the user associated with the JWT token, just call `@current_user` in the controller.

### API Versioning

The routes have been scoped and constrained to allow versioning of the api. Since the app store doesn't push updates to everyone at once and since some users don't always upgrade, a new version of the app could potentially break the app for people who still have an older version. To prevent this problem, any requests should have `Accept: version=n` in the header where `n` is the version. Only the controllers that match the version will be used.

### Tracking Client Builds

Tracking builds allows you to set different support levels for each build which can be interpreted by the client. For example, let's say we have 3 different versions of an app. What if we want/need to stop supporting s certain version?

The `Build` model has support level attributes. So build V3 of our app could have `support_level: 'active'` and everything works like normal. V2 could be `support_level: 'deprecated'` and would prompt a user to upgrade. V1 could be `support_level: 'unsupported'` which would force the use to upgrade.

An app should check it's build support level when the app load. It can do this by doing a `GET` request to `/builds/BUILD_NAME`. You can phase builds out as the app evolves or if you accidentally have a bug in the code you can force people to upgrade when there is a fix.

Here's how to keep track of this with git:

`git commit -m "message"`
`git tag build/610`
`git push origin branch && git push --tags origin branch`
