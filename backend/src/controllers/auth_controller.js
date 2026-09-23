import { AuthService } from '../services/auth_service.js';

export class AuthController {
  static register(req, res, next) {
    try {
      const { email, password, name, username } = req.body;
      if (!email || !password || !name) {
        return res.status(400).json({
          success: false,
          message: 'Email, password, and name are required',
        });
      }

      const generatedUsername = username || email.split('@')[0];
      const result = AuthService.register({
        email,
        password,
        name,
        username: generatedUsername,
      });

      res.status(201).json({
        success: true,
        message: 'Account created successfully',
        data: result,
      });
    } catch (err) {
      if (err.message.includes('already registered')) {
        return res.status(409).json({ success: false, message: err.message });
      }
      next(err);
    }
  }

  static login(req, res, next) {
    try {
      const { email, password } = req.body;
      if (!email || !password) {
        return res.status(400).json({
          success: false,
          message: 'Email and password are required',
        });
      }

      const result = AuthService.login({ email, password });
      res.json({
        success: true,
        message: 'Login successful',
        data: result,
      });
    } catch (err) {
      if (err.message.includes('Invalid email or password')) {
        return res.status(401).json({ success: false, message: err.message });
      }
      next(err);
    }
  }

  static me(req, res, next) {
    try {
      const user = AuthService.findById(req.user.id);
      if (!user) {
        return res.status(404).json({ success: false, message: 'User not found' });
      }
      res.json({ success: true, data: user });
    } catch (err) {
      next(err);
    }
  }

  static forgotPassword(req, res) {
    const { email } = req.body;
    if (!email) {
      return res.status(400).json({ success: false, message: 'Email is required' });
    }

    // In a production environment, send an email with a reset token
    res.json({
      success: true,
      message: `Password reset instructions have been sent to ${email}`,
    });
  }
}

