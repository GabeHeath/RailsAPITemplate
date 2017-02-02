### Create a User:

Send `POST` to `/users` with this information:

```javascript
{
  "user": {
    "email": 'test@example.com',
    "password": 'anewpassword',
    "password_confirmation": 'anewpassword'
  }
}
```

### Confirm a User:

Once a user is created they will recieve a token via email.

Send the token via `POST` to `/users/confirm` like this:

```javascript
{
  "token": { "TOKEN_HERE" }
}
```

### Login as a User:

To log in send a `POST` to `/users/login` with this information:

```javascript
{
  "email": "test@example.com",
  "password": "anewpassword"
}
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